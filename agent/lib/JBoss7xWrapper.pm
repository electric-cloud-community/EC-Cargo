# -------------------------------------------------------------------------
# File
#    JBoss7xWrapper.pl
#
# Dependencies
#    None
#
# Template Version
#    1.0
#
# Date
#    21/03/2012
#
# Engineer
#    Rafael Sanchez
#
# Copyright (c) 2012 Electric Cloud, Inc.
# All rights reserved
# -------------------------------------------------------------------------

package JBoss7xWrapper;
	
use warnings;
use XML::XPath;
use XML::XPath::XMLParser;
use ElectricCommander;
use strict;
use Cwd;
use File::Spec;
use ElectricCommander::PropDB;
use Time::Local;
use lib "$ENV{COMMANDER_PLUGINS}/@PLUGIN_NAME@/agent/lib";
use CargoCommon;

# -------------------------------------------------------------------------
# Main functions
# -------------------------------------------------------------------------

########################################################################
# deployJBoss - runs the command to make the deploy
#
# Arguments:
#   -propHash: hash containing path of the pom.xml file, the pon.xml as a xml object, the container, the location of the container, the user, password and url of the config
#
# Returns:
#   none
#
########################################################################
sub deployApp {	

	my $filePath = $_[1];
	my $container = $_[2];
	my $containerLocation = $_[3];
	my $containerPath = $_[4];
	my $user = $_[5];
	my $pass = $_[6];
	my $url =$_[7];
	my $groupId = "";
	my $artifactId = "";
	my $host = "";
	my $port = "";
    my %props;
	
	#execute command
	my $cmd = "mvn cargo:deploy -f \"$filePath\" -P $container -Dorg.jboss.as.client.connect.timeout=50000";
	
    #add masked command line to properties object
    $props{'cmdLine'} = $cmd;
    setProperties(\%props);
	
	#load the pom.xml file in a XML::XPath object
	my $xmlObj = XML::XPath->new(filename => $filePath);
		
	#checking if raw url comes in the format http(s)://whatever(:port)/(path)
	if($url =~ m/http(\w*):\/\/(\S[^:]*)(:*)(\d*)(\/*)(.*)/){
		$host = $2;
		$port = $4;
	}elsif($url =~ m/(\S[^:]*)(:*)(\d*)(\/*)(.*)/){
		$host = $1;
		$port = $3;
	}else{
		print "Error: Not a valid URL.\n";
		exit CargoCommon->ERROR;
	}        	
	
	#open the pom.xml file and load it in a string
	open FILE, $filePath or die "Couldn't open file: $!";
	my $strFile = join("", <FILE>); 

	#find all paragraphs in the file
	my $profileNodeset = $xmlObj->find('/project/profiles/profile'); 
	my $artifactNodeset = $xmlObj->find('/project/artifactId');
	my $groupNodeset = $xmlObj->find('/project/groupId'); 
		
	#find the artifactId
	foreach my $node ($artifactNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<artifactId>(.*)<\/artifactId>/) {
			$artifactId = $1;
		} 		
	}
	
	#find the groupId
	foreach my $node ($groupNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<groupId>(.*)<\/groupId>/) {
			$groupId = $1;
		} 		
	}	
	
	
	#load the configuration template of jboss to add to the pom.xml file
	my $configTemplate = CargoCommon->JBOSS7X_CONFIG;
				
	#if container is local, use local types and remove the url to use the home
	if ($containerLocation eq CargoCommon->LOCAL) {
		$configTemplate =~ s/<type>_deployType_<\/type>/<type>installed<\/type>/g;
		$configTemplate =~ s/<type>_configType_<\/type>/<type>existing<\/type>/g;
		$configTemplate =~ s/<home>_selectedContainer_<\/home>/<home>$containerPath<\/home>/g;
		$configTemplate =~ s/<home2>_selectedContainer_<\/home2>/<home>$containerPath\\standalone<\/home>/g;
		$configTemplate =~ s/<cargo.hostname>_jbossHost_<\/cargo.hostname>/<cargo.hostname>$host<\/cargo.hostname>/g;	
		$configTemplate =~ s/<cargo.servlet.port>_jbossPort_<\/cargo.servlet.port>/<cargo.servlet.port>$port<\/cargo.servlet.port>/g;	
		
		#check if the home path of the container exist, otherwise fail. This check is need because the deploy functions makes the deploy although the home dir don not exist.
		if (!(-d $containerPath)) {
			print "The home path of the container do not exist";
            $::gEC->setProperty("/myJobStep/outcome", 'error');			
			exit 1;
		}		
	} else {#if container is remote, use remote types and remove the home to use the url
		$configTemplate =~ s/<type>_deployType_<\/type>/<type>remote<\/type>/g;
		$configTemplate =~ s/<type>_configType_<\/type>/<type>runtime<\/type>/g;
		$configTemplate =~ s/<home2>_selectedContainer_<\/home2>//g;
		$configTemplate =~ s/<home>_selectedContainer_<\/home>//g;	
		$configTemplate =~ s/<cargo.hostname>_jbossHost_<\/cargo.hostname>/<cargo.hostname>$host<\/cargo.hostname>/g;	
		$configTemplate =~ s/<cargo.servlet.port>_jbossPort_<\/cargo.servlet.port>/<cargo.servlet.port>1$port<\/cargo.servlet.port>/g;	
	}
		
	#add the context path, if exist
	if ($::gContextPath && $::gContextPath ne '') {
		$configTemplate =~ s/<context>_contextPath_<\/context>/<context>$::gContextPath<\/context>/g;		
	} else {
		$configTemplate =~ s/<context>_contextPath_<\/context>//g;		
	}
	
	
	#preplace in the template the jboss container values
	$configTemplate =~ s/<groupId>_groupId_<\/groupId>/<groupId>$groupId<\/groupId>/g;
	$configTemplate =~ s/<artifactId>_artifactId_<\/artifactId>/<artifactId>$artifactId<\/artifactId>/g;
	$configTemplate =~ s/<cargo.remote.username>_jbossUser_<\/cargo.remote.username>/<cargo.remote.username>$user<\/cargo.remote.username>/g;
	$configTemplate =~ s/<cargo.remote.password>_jbossPass_<\/cargo.remote.password>/<cargo.remote.password>$pass<\/cargo.remote.password>/g;
	
	#replace in the pom.xml file the "jboss7x" container value for the modified template
	foreach my $node ($profileNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<id>jboss7x<\/id>/) {				
			if ($strFile =~ m/<id>jboss7x<\/id>(.*)<\/build>/s) {
				$strFile =~ s/<id>jboss7x<\/id>(.*)<\/build>/$configTemplate/s;
			}
		} 		
		open DATA, ">$filePath" or die "can't open $filePath $!";
		printf DATA $strFile;
		close (DATA);
	}
	
	my $content = `$cmd`;			
	print $content;
	
	#show the result
    if ($? == CargoCommon->SUCCESS) {
        if ($content =~ m/BUILD FAILURE/) {
            $::gEC->setProperty("/myJobStep/outcome", 'error');
        }elsif ($content =~ m/BUILD SUCCESS/) {   
            $::gEC->setProperty("/myJobStep/outcome", 'success');
        }else {
            $::gEC->setProperty("/myJobStep/outcome", 'warning');
		}
	} else{
        $::gEC->setProperty("/myJobStep/outcome", 'error');
    }
}

########################################################################
# undeployJBoss - runs the command to make the undeploy
#
# Arguments:
#   -propHash: hash containing path of the pom.xml file, the pon.xml as a xml object, the container, the location of the container, the user, password and url of the config
#
# Returns:
#   none
#
########################################################################
sub undeployApp {	

	my $filePath = $_[1];
	my $container = $_[2];
	my $containerLocation = $_[3];
	my $containerPath = $_[4];
	my $user = $_[5];
	my $pass = $_[6];
	my $url =$_[7];
	
	my $groupId = "";
	my $artifactId = "";
	my $host = "";
	my $port = "";
    my %props;
		
	#execute command
	my $cmd = "mvn cargo:undeploy -f \"$filePath\" -P $container -Dorg.jboss.as.client.connect.timeout=50000";
		
    #add masked command line to properties object
    $props{'cmdLine'} = $cmd;

    setProperties(\%props);
	
	#checking if raw url comes in the format http(s)://whatever(:port)/(path)
	if($url =~ m/http(\w*):\/\/(\S[^:]*)(:*)(\d*)(\/*)(.*)/){
		$host = $2;
		$port = $4;
	}elsif($url =~ m/(\S[^:]*)(:*)(\d*)(\/*)(.*)/){
		$host = $1;
		$port = $3;
	}else{
		print "Error: Not a valid URL.\n";
		exit CargoCommon->ERROR;
	}        	
	
	#load the pom.xml file in a XML::XPath object
	my $xmlObj = XML::XPath->new(filename => $filePath);
	
	#open the pom.xml file and load it in a string
	open FILE, $filePath or die "Couldn't open file: $!";
	my $strFile = join("", <FILE>); 

	#find all paragraphs in the file
	my $profileNodeset = $xmlObj->find('/project/profiles/profile'); 
	my $artifactNodeset = $xmlObj->find('/project/artifactId');
	my $groupNodeset = $xmlObj->find('/project/groupId'); 
		
	#find the artifactId
	foreach my $node ($artifactNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<artifactId>(.*)<\/artifactId>/) {
			$artifactId = $1;
		} 		
	}
	
	#find the groupId
	foreach my $node ($groupNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<groupId>(.*)<\/groupId>/) {
			$groupId = $1;
		} 		
	}	
	
	#load the configuration template of jboss to add to the pom.xml file
	my $configTemplate = CargoCommon->JBOSS7X_CONFIG;
			
	#if container is local, use local types and remove the url to use the home
	if ($containerLocation eq CargoCommon->LOCAL) {
		$configTemplate =~ s/<type>_deployType_<\/type>/<type>installed<\/type>/g;
		$configTemplate =~ s/<type>_configType_<\/type>/<type>existing<\/type>/g;
		$configTemplate =~ s/<home>_selectedContainer_<\/home>/<home>$containerPath<\/home>/g;
		$configTemplate =~ s/<home2>_selectedContainer_<\/home2>/<home>$containerPath\\standalone<\/home>/g;
		$configTemplate =~ s/<cargo.hostname>_jbossHost_<\/cargo.hostname>/<cargo.hostname>$host<\/cargo.hostname>/g;	
		$configTemplate =~ s/<cargo.servlet.port>_jbossPort_<\/cargo.servlet.port>/<cargo.servlet.port>$port<\/cargo.servlet.port>/g;	
		
		#check if the home path of the container exist, otherwise fail. This check is need because the deploy functions makes the deploy although the home dir don not exist.
		if (!(-d $containerPath)) {
			print "The home path of the container do not exist";
            $::gEC->setProperty("/myJobStep/outcome", 'error');			
			exit 1;
		}		
	} else {#if container is remote, use remote types and remove the home to use the url
		$configTemplate =~ s/<type>_deployType_<\/type>/<type>remote<\/type>/g;
		$configTemplate =~ s/<type>_configType_<\/type>/<type>runtime<\/type>/g;
		$configTemplate =~ s/<home2>_selectedContainer_<\/home2>//g;
		$configTemplate =~ s/<home>_selectedContainer_<\/home>//g;	
		$configTemplate =~ s/<cargo.hostname>_jbossHost_<\/cargo.hostname>/<cargo.hostname>$host<\/cargo.hostname>/g;	
		$configTemplate =~ s/<cargo.servlet.port>_jbossPort_<\/cargo.servlet.port>/<cargo.servlet.port>1$port<\/cargo.servlet.port>/g;	
	}
		
	#add the context path, if exist
	if ($::gContextPath && $::gContextPath ne '') {
		$configTemplate =~ s/<context>_contextPath_<\/context>/<context>$::gContextPath<\/context>/g;		
	} else {
		$configTemplate =~ s/<context>_contextPath_<\/context>//g;		
	}
	
	
	#preplace in the template the jboss container values
	$configTemplate =~ s/<groupId>_groupId_<\/groupId>/<groupId>$groupId<\/groupId>/g;
	$configTemplate =~ s/<artifactId>_artifactId_<\/artifactId>/<artifactId>$artifactId<\/artifactId>/g;
	$configTemplate =~ s/<cargo.remote.username>_jbossUser_<\/cargo.remote.username>/<cargo.remote.username>$user<\/cargo.remote.username>/g;
	$configTemplate =~ s/<cargo.remote.password>_jbossPass_<\/cargo.remote.password>/<cargo.remote.password>$pass<\/cargo.remote.password>/g;
	
	#replace in the pom.xml file the "jboss7x" container value for the modified template
	foreach my $node ($profileNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<id>jboss7x<\/id>/) {				
			if ($strFile =~ m/<id>jboss7x<\/id>(.*)<\/build>/s) {
				$strFile =~ s/<id>jboss7x<\/id>(.*)<\/build>/$configTemplate/s;
			}
		} 		
		open DATA, ">$filePath" or die "can't open $filePath $!";
		printf DATA $strFile;
		close (DATA);
	}

	my $content = `$cmd`;		
	print $content;
	
	#show the result
    if ($? == CargoCommon->SUCCESS) {
        if ($content =~ m/BUILD FAILURE/) {
            $::gEC->setProperty("/myJobStep/outcome", 'error');
        }elsif ($content =~ m/BUILD SUCCESS/) {   
            $::gEC->setProperty("/myJobStep/outcome", 'success');
        }else {
            $::gEC->setProperty("/myJobStep/outcome", 'warning');
		}
	} else{
        $::gEC->setProperty("/myJobStep/outcome", 'error');
    }	
}

sub verifyContainer {	
	my $container = $_[1];
	my $user = $_[2];
	my $pass = $_[3];
	my $url = $_[4];
	my $successCriteria = $_[5];

	my $urlJBoss = $url . "/console/App.html#deployment-list";
	
    #create all objects needed for response-request operations
    my $agent = LWP::UserAgent->new(env_proxy => 1,keep_alive => 1, timeout => 30);
    my $header = HTTP::Request->new(GET => $urlJBoss);
    my $request = HTTP::Request->new('GET', $urlJBoss, $header);
	
	#enter BASIC authentication
    if($user ne ''){    
        $request->authorization_basic($user, $pass);
    }	
	
	my $response = $agent->request($request);	
		
	# Check the outcome of the response
	if ($response->is_success && $successCriteria eq "start"){		
		print "The container is running.";
		$::gEC->setProperty("/myJobStep/outcome", 'success');			
	}elsif ($response->is_error && $successCriteria eq "start"){		
		#response was erroneus, either server doesn't exist, port is unavailable
		#or server is overloaded. A HTTP 5XX response code can be expected
		print "Error starting the container.";
		$::gEC->setProperty("/myJobStep/outcome", 'error');
	} elsif ($response->is_success && $successCriteria eq "stop"){		
		print "The container is still running.";
		$::gEC->setProperty("/myJobStep/outcome", 'error');			
	}elsif ($response->is_error && $successCriteria eq "stop"){		
		#response was erroneus, either server doesn't exist, port is unavailable
		#or server is overloaded. A HTTP 5XX response code can be expected
		print "The container is not running.";
		$::gEC->setProperty("/myJobStep/outcome", 'success');
	}              
}

########################################################################
# runContainer - runs the command to start the container, and deploy app if specified
#
# Arguments:
#   -propHash: hash containing path of the pom.xml file, the pon.xml as a xml object, the container, the location of the container, the user, password and url of the config
#
# Returns:
#   none
#
########################################################################
sub runContainer {		
	
	my $filePath = $_[1];
	my $container = $_[2];
	my $containerLocation = $_[3];
	my $containerPath = $_[4];
	my $user = $_[5];
	my $pass = $_[6];
	my $url =$_[7];
	my $groupId = "";
	my $artifactId = "";
	my $host = "";
	my $port = "";
    my %props;
		
	my $cmd = "mvn cargo:run -f \"$filePath\" -P $container";
	
    #add masked command line to properties object	
    $props{'cmdLine'} = $cmd;
    setProperties(\%props);	

	#checking if raw url comes in the format http(s)://whatever(:port)/(path)
	if($url =~ m/http(\w*):\/\/(\S[^:]*)(:*)(\d*)(\/*)(.*)/){
		$host = $2;
		$port = $4;
	}elsif($url =~ m/(\S[^:]*)(:*)(\d*)(\/*)(.*)/){
		$host = $1;
		$port = $3;
	}else{
		print "Error: Not a valid URL.\n";
		exit CargoCommon->ERROR;
	}        	
	
	#load the pom.xml file in a XML::XPath object
	my $xmlObj = XML::XPath->new(filename => $filePath);
	
	my $LOGNAMEBASE = "cargoRun";
	my $operatingSystem = $^O;
	my $justRun = $::gDeployApp;
	
	#open the pom.xml file and load it in a string
	open FILE, $filePath or die "Couldn't open file: $!";
	my $strFile = join("", <FILE>); 

	#find all paragraphs in the file
	my $profileNodeset = $xmlObj->find('/project/profiles/profile'); 
	my $artifactNodeset = $xmlObj->find('/project/artifactId');
	my $groupNodeset = $xmlObj->find('/project/groupId'); 
		
	#find the artifactId
	foreach my $node ($artifactNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<artifactId>(.*)<\/artifactId>/) {
			$artifactId = $1;
		} 		
	}
	
	#find the groupId
	foreach my $node ($groupNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<groupId>(.*)<\/groupId>/) {
			$groupId = $1;
			$::gContextPath = $groupId;
		} 		
	}	
	
	#load the configuration template of jboss to add to the pom.xml file
	my $configTemplate = CargoCommon->JBOSS7X_CONFIG;
						
	#if container is local, use local types and remove the url to use the home
	if ($containerLocation eq CargoCommon->LOCAL) {
		$configTemplate =~ s/<type>_deployType_<\/type>/<type>installed<\/type>/g;
		$configTemplate =~ s/<type>_configType_<\/type>/<type>existing<\/type>/g;
		$configTemplate =~ s/<home>_selectedContainer_<\/home>/<home>$containerPath<\/home>/g;
		$configTemplate =~ s/<home2>_selectedContainer_<\/home2>/<home>$containerPath\\standalone<\/home>/g;
		$configTemplate =~ s/<cargo.hostname>_jbossHost_<\/cargo.hostname>/<cargo.hostname>$host<\/cargo.hostname>/g;	
		$configTemplate =~ s/<cargo.servlet.port>_jbossPort_<\/cargo.servlet.port>/<cargo.servlet.port>$port<\/cargo.servlet.port>/g;	
		
		#check if the home path of the container exist, otherwise fail. This check is need because the deploy functions makes the deploy although the home dir don not exist.
		if (!(-d $containerPath)) {
			print "The home path of the container do not exist";
            $::gEC->setProperty("/myJobStep/outcome", 'error');			
			exit 1;
		}		
	} else {#if container is remote, use remote types and remove the home to use the url
		$configTemplate =~ s/<type>_deployType_<\/type>/<type>remote<\/type>/g;
		$configTemplate =~ s/<type>_configType_<\/type>/<type>runtime<\/type>/g;
		$configTemplate =~ s/<home2>_selectedContainer_<\/home2>/<home>$containerPath\\standalone<\/home>/g;
		$configTemplate =~ s/<home>_selectedContainer_<\/home>//g;	
		$configTemplate =~ s/<cargo.hostname>_jbossHost_<\/cargo.hostname>/<cargo.hostname>$host<\/cargo.hostname>/g;	
		$configTemplate =~ s/<cargo.servlet.port>_jbossPort_<\/cargo.servlet.port>/<cargo.servlet.port>$port<\/cargo.servlet.port>/g;	
	}
	
	#add the context path
	$configTemplate =~ s/<context>_contextPath_<\/context>/<context>$::gContextPath<\/context>/s;				
		
	#preplace in the template the jboss container values
	$configTemplate =~ s/<groupId>_groupId_<\/groupId>/<groupId>$groupId<\/groupId>/g;
	$configTemplate =~ s/<artifactId>_artifactId_<\/artifactId>/<artifactId>$artifactId<\/artifactId>/g;
	$configTemplate =~ s/<cargo.remote.username>_jbossUser_<\/cargo.remote.username>/<cargo.remote.username>$user<\/cargo.remote.username>/g;
	$configTemplate =~ s/<cargo.remote.password>_jbossPass_<\/cargo.remote.password>/<cargo.remote.password>$pass<\/cargo.remote.password>/g;
		
	#replace in the pom.xml file the "jboss7x" container value for the modified template
	foreach my $node ($profileNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<id>jboss7x<\/id>/) {				
			if ($strFile =~ m/<id>jboss7x<\/id>(.*)<\/build>/s) {
				$strFile =~ s/<id>jboss7x<\/id>(.*)<\/build>/$configTemplate/s;
			}
		} 		
		open DATA, ">$filePath" or die "can't open $filePath $!";
		printf DATA $strFile;
		close (DATA);
	}
	
	my @systemcall;
	  
	if($operatingSystem eq CargoCommon->WIN_IDENTIFIER) {

		# Windows has a much more complex execution and quoting problem. First, we cannot just execute under "cmd.exe"
		# because ecdaemon automatically puts quote marks around every parameter passed to it -- but the "/K" and "/C"
		# option to cmd.exe can't have quotes (it sees the option as a parameter not an option to itself). To avoid this, we
		# use "ec-perl -e xxx" to execute a one-line script that we create on the fly. The one-line script is an "exec()"
		# call to our shell script. Unfortunately, each of these wrappers strips away or interprets certain metacharacters
		# -- quotes, embedded spaces, and backslashes in particular. We end up escaping these metacharacters repeatedly so
		# that when it gets to the last level it's a nice simple script call. Most of this was determined by trial and error
		# using the sysinternals procmon tool.
		my $commandline = CargoCommon->BSLASH . CargoCommon->BSLASH . CargoCommon->BSLASH . CargoCommon->DQUOTE . $cmd . CargoCommon->BSLASH . CargoCommon->BSLASH . CargoCommon->BSLASH . CargoCommon->DQUOTE;
		my $logfile = $LOGNAMEBASE . "-" . $ENV{'COMMANDER_JOBSTEPID'} . ".log";
		my $errfile = $LOGNAMEBASE . "-" . $ENV{'COMMANDER_JOBSTEPID'} . ".err";
		$commandline = CargoCommon->SQUOTE . $commandline . " 1>" . $logfile . " 2>" . $errfile . CargoCommon->SQUOTE;
		$commandline = "exec(" . $commandline . ");";
		$commandline = CargoCommon->DQUOTE . $commandline . CargoCommon->DQUOTE;
		@systemcall = ("ecdaemon", "--", "ec-perl", "-e", $commandline);

	} else {

		# Linux is comparatively simple, just some quotes around the script name in case of embedded spaces.
		# IMPORTANT NOTE: At this time the direct output of the script is lost in Linux, as I have not figured out how to
		# safely redirect it. Nothing shows up in the log file even when I appear to get the redirection correct; I believe
		# the script might be putting the output to /dev/tty directly (or something equally odd). Most of the time, it's not
		# really important since the vital information goes directly to $CATALINA_HOME/logs/catalina.out anyway. It can lose
		# important error messages if the paths are bad, etc. so this will be a JIRA.

		@systemcall = ($cmd . " &");

	}
	
	my $cmdLine = createCommandLine(\@systemcall);
	
	my $content = system($cmdLine);
}

########################################################################
# stopContainer - runs the command to stop the container
#
# Arguments:
#   -propHash: hash containing path of the pom.xml file, the pon.xml as a xml object, the container, the location of the container, the user, password and url of the config
#
# Returns:
#   none
#
########################################################################
sub stopContainer {		
	
	my $filePath = $_[1];
	my $container = $_[2];
	my $containerLocation = $_[3];
	my $containerPath = $_[4];
	my $user = $_[5];
	my $pass = $_[6];
	my $url =$_[7];
	my $groupId = "";
	my $artifactId = "";
	my $host = "";
	my $port = "";
    my %props;	
	
	my $cmd = "mvn cargo:stop -f \"$filePath\" -P $container";
	
    #add masked command line to properties object
    $props{'cmdLine'} = $cmd;
    setProperties(\%props);
	
	#checking if raw url comes in the format http(s)://whatever(:port)/(path)
	if($url =~ m/http(\w*):\/\/(\S[^:]*)(:*)(\d*)(\/*)(.*)/){
		$host = $2;
		$port = $4;
	}elsif($url =~ m/(\S[^:]*)(:*)(\d*)(\/*)(.*)/){
		$host = $1;
		$port = $3;
	}else{
		print "Error: Not a valid URL.\n";
		exit CargoCommon->ERROR;
	}        	
	
	#load the pom.xml file in a XML::XPath object
	my $xmlObj = XML::XPath->new(filename => $filePath);
	
	my $LOGNAMEBASE = "cargoStop";
	my $operatingSystem = $^O;
	my $justRun = $::gDeployApp;
	
	#open the pom.xml file and load it in a string
	open FILE, $filePath or die "Couldn't open file: $!";
	my $strFile = join("", <FILE>); 

	#find all paragraphs in the file
	my $profileNodeset = $xmlObj->find('/project/profiles/profile'); 
	my $artifactNodeset = $xmlObj->find('/project/artifactId');
	my $groupNodeset = $xmlObj->find('/project/groupId'); 
		
	#find the artifactId
	foreach my $node ($artifactNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<artifactId>(.*)<\/artifactId>/) {
			$artifactId = $1;
		} 		
	}
	
	#find the groupId
	foreach my $node ($groupNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<groupId>(.*)<\/groupId>/) {
			$groupId = $1;
			$::gContextPath = $groupId;
		} 		
	}	
	
	#load the configuration template of jboss to add to the pom.xml file
	my $configTemplate = CargoCommon->JBOSS7X_CONFIG;
						
	#if container is local, use local types and remove the url to use the home
	if ($containerLocation eq CargoCommon->LOCAL) {
		$configTemplate =~ s/<type>_deployType_<\/type>/<type>installed<\/type>/g;
		$configTemplate =~ s/<type>_configType_<\/type>/<type>existing<\/type>/g;
		$configTemplate =~ s/<home>_selectedContainer_<\/home>/<home>$containerPath<\/home>/g;
		$configTemplate =~ s/<home2>_selectedContainer_<\/home2>/<home>$containerPath\\standalone<\/home>/g;
		$configTemplate =~ s/<cargo.hostname>_jbossHost_<\/cargo.hostname>/<cargo.hostname>$host<\/cargo.hostname>/g;	
		$configTemplate =~ s/<cargo.servlet.port>_jbossPort_<\/cargo.servlet.port>/<cargo.servlet.port>$port<\/cargo.servlet.port>/g;	
		
		#check if the home path of the container exist, otherwise fail. This check is need because the deploy functions makes the deploy although the home dir don not exist.
		if (!(-d $containerPath)) {
			print "The home path of the container do not exist";
            $::gEC->setProperty("/myJobStep/outcome", 'error');			
			exit 1;
		}		
	} else {#if container is remote, use remote types and remove the home to use the url
		$configTemplate =~ s/<type>_deployType_<\/type>/<type>remote<\/type>/g;
		$configTemplate =~ s/<type>_configType_<\/type>/<type>runtime<\/type>/g;
		$configTemplate =~ s/<home2>_selectedContainer_<\/home2>/<home>$containerPath\\standalone<\/home>/g;
		$configTemplate =~ s/<home>_selectedContainer_<\/home>//g;	
		$configTemplate =~ s/<cargo.hostname>_jbossHost_<\/cargo.hostname>/<cargo.hostname>$host<\/cargo.hostname>/g;	
		$configTemplate =~ s/<cargo.servlet.port>_jbossPort_<\/cargo.servlet.port>/<cargo.servlet.port>$port<\/cargo.servlet.port>/g;	
	}
		
	#add the context path
	$configTemplate =~ s/<context>_contextPath_<\/context>/<context>$::gContextPath<\/context>/s;				
		
	#preplace in the template the jboss container values
	$configTemplate =~ s/<groupId>_groupId_<\/groupId>/<groupId>$groupId<\/groupId>/g;
	$configTemplate =~ s/<artifactId>_artifactId_<\/artifactId>/<artifactId>$artifactId<\/artifactId>/g;
	$configTemplate =~ s/<cargo.remote.username>_jbossUser_<\/cargo.remote.username>/<cargo.remote.username>$user<\/cargo.remote.username>/g;
	$configTemplate =~ s/<cargo.remote.password>_jbossPass_<\/cargo.remote.password>/<cargo.remote.password>$pass<\/cargo.remote.password>/g;
		
	#replace in the pom.xml file the "jboss7x" container value for the modified template
	foreach my $node ($profileNodeset->get_nodelist) {
		my $nodeStr = XML::XPath::XMLParser::as_string($node);   
	
		if ($nodeStr =~ m/<id>jboss7x<\/id>/) {				
			if ($strFile =~ m/<id>jboss7x<\/id>(.*)<\/build>/s) {
				$strFile =~ s/<id>jboss7x<\/id>(.*)<\/build>/$configTemplate/s;
			}
		} 		
		open DATA, ">$filePath" or die "can't open $filePath $!";
		printf DATA $strFile;
		close (DATA);
	}
	
	my @systemcall;
	  
	if($operatingSystem eq CargoCommon->WIN_IDENTIFIER) {

		# Windows has a much more complex execution and quoting problem. First, we cannot just execute under "cmd.exe"
		# because ecdaemon automatically puts quote marks around every parameter passed to it -- but the "/K" and "/C"
		# option to cmd.exe can't have quotes (it sees the option as a parameter not an option to itself). To avoid this, we
		# use "ec-perl -e xxx" to execute a one-line script that we create on the fly. The one-line script is an "exec()"
		# call to our shell script. Unfortunately, each of these wrappers strips away or interprets certain metacharacters
		# -- quotes, embedded spaces, and backslashes in particular. We end up escaping these metacharacters repeatedly so
		# that when it gets to the last level it's a nice simple script call. Most of this was determined by trial and error
		# using the sysinternals procmon tool.
		my $commandline = CargoCommon->BSLASH . CargoCommon->BSLASH . CargoCommon->BSLASH . CargoCommon->DQUOTE . $cmd . CargoCommon->BSLASH . CargoCommon->BSLASH . CargoCommon->BSLASH . CargoCommon->DQUOTE;
		my $logfile = $LOGNAMEBASE . "-" . $ENV{'COMMANDER_JOBSTEPID'} . ".log";
		my $errfile = $LOGNAMEBASE . "-" . $ENV{'COMMANDER_JOBSTEPID'} . ".err";
		$commandline = CargoCommon->SQUOTE . $commandline . " 1>" . $logfile . " 2>" . $errfile . CargoCommon->SQUOTE;
		$commandline = "exec(" . $commandline . ");";
		$commandline = CargoCommon->DQUOTE . $commandline . CargoCommon->DQUOTE;
		@systemcall = ("ecdaemon", "--", "ec-perl", "-e", $commandline);

	} else {

		# Linux is comparatively simple, just some quotes around the script name in case of embedded spaces.
		# IMPORTANT NOTE: At this time the direct output of the script is lost in Linux, as I have not figured out how to
		# safely redirect it. Nothing shows up in the log file even when I appear to get the redirection correct; I believe
		# the script might be putting the output to /dev/tty directly (or something equally odd). Most of the time, it's not
		# really important since the vital information goes directly to $CATALINA_HOME/logs/catalina.out anyway. It can lose
		# important error messages if the paths are bad, etc. so this will be a JIRA.

		@systemcall = ($cmd . " &");

	}
	
	my $cmdLine = createCommandLine(\@systemcall);
		
	my $content = system($cmdLine);		
}

########################################################################
# setProperties - set a group of properties into the Electric Commander
#
# Arguments:
#   -propHash: hash containing the ID and the value of the properties 
#              to be written into the Electric Commander
#
# Returns:
#   none
#
########################################################################
sub setProperties($) {
	my ($propHash) = @_;
	foreach my $key (keys % $propHash) {
		my $val = $propHash->{$key};
		$::gEC->setProperty("/myCall/$key", $val);
	}
}

########################################################################
# createCommandLine - creates the command line for the invocation
# of the program to be executed.
#
# Arguments:
#   -arr: array containing the command name (must be the first element) 
#         and the arguments entered by the user in the UI
#
# Returns:
#   -the command line to be executed by the plugin
#
########################################################################
sub createCommandLine($) {
	my ($arr) = @_;
	my $commandName = @$arr[0];
	my $command = $commandName;
	shift(@$arr);
	foreach my $elem (@$arr) {
		$command .= " $elem";
	}
	return $command; 
}

return 1;
exit;