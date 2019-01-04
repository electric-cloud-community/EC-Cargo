my %deployApp = (
    label       => "Cargo - Deploy Application",
    procedure   => "DeployApp",
    description => "Deploys or redeploys an application or module using cargo.",
    category    => "Resource Management"
);
my %undeployApp = (
    label       => "Cargo - Undeploy Application",
    procedure   => "UndeployApp",
    description => "Undeploys an application or module using cargo.",
    category    => "Resource Management"
);
my %runContainer = (
    label       => "Cargo - Run Container",
    procedure   => "RunContainer",
    description => "Runs the selected container and deploys the selected application.",
    category    => "Resource Management"
);
my %stopContainer = (
    label       => "Cargo - Stop Container",
    procedure   => "StopContainer",
    description => "Runs the selected container.",
    category    => "Resource Management"
);

$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-Cargo - Deploy App");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-Cargo - Undeploy App");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-Cargo - Run Container");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-Cargo - Stop Container");

$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cargo - Deploy App");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cargo - Undeploy App");

$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cargo - Deploy Application");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cargo - Undeploy Application");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cargo - Run Container");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/Cargo - Stop Container");

@::createStepPickerSteps = (\%deployApp, \%undeployApp, \%runContainer, \%stopContainer);

if ($upgradeAction eq "upgrade") {
    my $query = $commander->newBatch();
    my $newcfg = $query->getProperty(
        "/plugins/$pluginName/project/cargo_cfgs");
    my $oldcfgs = $query->getProperty(
        "/plugins/$otherPluginName/project/cargo_cfgs");
	my $creds = $query->getCredentials(
        "\$[/plugins/$otherPluginName]");

	local $self->{abortOnError} = 0;
    $query->submit();

    # if new plugin does not already have cfgs
    if ($query->findvalue($newcfg,"code") eq "NoSuchProperty") {
        # if old cfg has some cfgs to copy
        if ($query->findvalue($oldcfgs,"code") ne "NoSuchProperty") {
            $batch->clone({
                path => "/plugins/$otherPluginName/project/cargo_cfgs",
                cloneName => "/plugins/$pluginName/project/cargo_cfgs"
            });
        }
    }
	
	# Copy configuration credentials and attach them to the appropriate steps
    my $nodes = $query->find($creds);
    if ($nodes) {
        my @nodes = $nodes->findnodes("credential/credentialName");
        for (@nodes) {
            my $cred = $_->string_value;

            # Clone the credential
            $batch->clone({
                path => "/plugins/$otherPluginName/project/credentials/$cred",
                cloneName => "/plugins/$pluginName/project/credentials/$cred"
            });

            # Make sure the credential has an ACL entry for the new project principal
            my $xpath = $commander->getAclEntry("user", "project: $pluginName", {
                projectName => $otherPluginName,
                credentialName => $cred
            });
            if ($xpath->findvalue("//code") eq "NoSuchAclEntry") {
                $batch->deleteAclEntry("user", "project: $otherPluginName", {
                    projectName => $pluginName,
                    credentialName => $cred
                });
                $batch->createAclEntry("user", "project: $pluginName", {
                    projectName => $pluginName,
                    credentialName => $cred,
                    readPrivilege => 'allow',
                    modifyPrivilege => 'allow',
                    executePrivilege => 'allow',
                    changePermissionsPrivilege => 'allow'
                });
            }
            # Attach the credential to the appropriate steps
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'DeployApp',
                stepName => 'DeployApp'
            });       
            # Attach the credential to the appropriate steps
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'UndeployApp',
                stepName => 'UndeployApp'
            });           
            # Attach the credential to the appropriate steps
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'RunContainer',
                stepName => 'RunContainer'
            });       
            # Attach the credential to the appropriate steps
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'StopContainer',
                stepName => 'StopContainer'
            });         
        }
    }
}
