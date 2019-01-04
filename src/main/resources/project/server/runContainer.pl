# -------------------------------------------------------------------------
# File
#    runContainer.pl
#
# Dependencies
#    None
#
# Template Version
#    1.0
#
# Date
#    19/03/2012
#
# Engineer
#    Rafael Sanchez
#
# Copyright (c) 2012 Electric Cloud, Inc.
# All rights reserved
# -------------------------------------------------------------------------

use warnings;
use ElectricCommander;
use strict;
use Cwd;
use File::Spec;
use ElectricCommander::PropDB;
use Time::Local;
use LWP::UserAgent;
use HTTP::Request;

use lib "$ENV{COMMANDER_PLUGINS}/@PLUGIN_NAME@/agent/lib";
use CargoCommon;
use Tomcat6xWrapper;
use Jetty8xWrapper;
use JBoss7xWrapper;
use WebLogic103xWrapper;

$|=1; 


# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------	
$::gEC = new ElectricCommander();
$::gEC->abortOnError(0);
  
$::gAppPath = ($::gEC->getProperty("appPath") )->findvalue("//value");
$::gConfig = ($::gEC->getProperty("configname") )->findvalue("//value");
$::gSleep = ($::gEC->getProperty("timelimit") )->findvalue("//value");

# -------------------------------------------------------------------------
# Main functions
# -------------------------------------------------------------------------

########################################################################
# main - contains the whole process to be done by the plugin, it builds 
#        the command line, sets the properties and the working directory
#
# Arguments:
#   none
#
# Returns:
#   none
#
########################################################################

sub main() {
	#config
    my %configuration;      
    my $container = '';
    my $containerLocation = '';
    my $containerPath = '';
    my $user = '';
    my $pass = '';
    my $url = '';
	my $filePath = '';
	
	#path of the pom.xml file
	if ($::gAppPath && $::gAppPath ne '') {
		$filePath = $::gAppPath . "\\pom.xml";
	}
	
    #getting all info from the configuration, url, user and pass
    if($::gConfig ne ''){        
        %configuration = getConfiguration($::gConfig);
        $container = $configuration{'container'};
		$containerLocation = $configuration{'containerLocation'};
        $containerPath = $configuration{'containerPath'};
		$user = $configuration{'user'};
        $pass = $configuration{'password'};
        $url = $configuration{'url'};
    }
	
	if ($containerLocation eq CargoCommon->REMOTE) {
		print "Only local containers can be started";
		$::gEC->setProperty("/myJobStep/outcome", 'error');		
	} else {		
		#if the container is "tomcat6x"
		if ($container eq CargoCommon->TOMCAT6X_TYPE) {
			Tomcat6xWrapper->runContainer($filePath, $container, $containerLocation, $containerPath, $user, $pass, $url);
			sleep $::gSleep;		
			Tomcat6xWrapper->verifyContainer($container, $user, $pass, $url, "start");
		} elsif ($container eq CargoCommon->JETTY8X_TYPE) {
			print "Jetty run local container not supported";
			$::gEC->setProperty("/myJobStep/outcome", 'error');					
		} elsif ($container eq CargoCommon->JBOSS7X_TYPE) {
			JBoss7xWrapper->runContainer($filePath, $container, $containerLocation, $containerPath, $user, $pass, $url);
			sleep $::gSleep;		
			JBoss7xWrapper->verifyContainer($container, $user, $pass, $url, "start");
		} elsif ($container eq CargoCommon->WEBLOGIC10X_TYPE) {
			WebLogic103xWrapper->runContainer($filePath, $container, $containerLocation, $containerPath, $user, $pass, $url);
			sleep $::gSleep;		
			WebLogic103xWrapper->verifyContainer($container, $user, $pass, $url, "start");
		}	
	}
}

##########################################################################

# getConfiguration - get the information of the configuration given
#
# Arguments:
#   -configName: name of the configuration to retrieve
#
# Returns:
#   -configToUse: hash containing the configuration information
#
#########################################################################

sub getConfiguration($){
	my ($configName) = @_;
	my %configToUse;

	my $proj = "$[/myProject/projectName]";
	my $pluginConfigs = new ElectricCommander::PropDB($::gEC,"/projects/$proj/cargo_cfgs");

	my %configRow = $pluginConfigs->getRow($configName);

	# Check if configuration exists
	unless(keys(%configRow)) {

		print 'Error: Configuration doesn\'t exist';
		exit CargoCommon->ERROR;
	}

	# Get user/password out of credential
	my $xpath = $::gEC->getFullCredential($configRow{credential});
	$configToUse{'user'} = $xpath->findvalue("//userName");
	$configToUse{'password'} = $xpath->findvalue("//password");

	foreach my $c (keys %configRow) {
		#getting all values except the credential that was read previously
		if($c ne CargoCommon->CREDENTIAL_ID){
			$configToUse{$c} = $configRow{$c};
		}	  
	}
	return %configToUse;
}

main();

1;