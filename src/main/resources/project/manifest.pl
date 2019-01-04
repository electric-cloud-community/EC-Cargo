@files = (
	['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="CargoCreateConfigForm"]/value'  , 'CargoCreateConfigForm.xml'],
	['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="CargoEditConfigForm"]/value'  , 'CargoEditConfigForm.xml'],
	 
	['//property[propertyName="deployer_matchers"]/value', 'matchers/deployerMatchers.pl'],
	['//property[propertyName="undeployer_matchers"]/value', 'matchers/undeployerMatchers.pl'],
	['//property[propertyName="runner_matchers"]/value', 'matchers/runnerMatchers.pl'],
	['//property[propertyName="stopper_matchers"]/value', 'matchers/stopperMatchers.pl'],
		
	['//procedure[procedureName="DeployApp"]/step[stepName="DeployApp"]/command' , 'server/deployApp.pl'],
	['//procedure[procedureName="UndeployApp"]/step[stepName="UndeployApp"]/command' , 'server/undeployApp.pl'],
	['//procedure[procedureName="RunContainer"]/step[stepName="RunContainer"]/command' , 'server/runContainer.pl'],
	['//procedure[procedureName="StopContainer"]/step[stepName="StopContainer"]/command' , 'server/stopContainer.pl'],
	
	['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateConfiguration"]/command' , 'conf/createcfg.pl'],
	['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateAndAttachCredential"]/command' , 'conf/createAndAttachCredential.pl'],
	['//procedure[procedureName="DeleteConfiguration"]/step[stepName="DeleteConfiguration"]/command' , 'conf/deletecfg.pl'],
	
	['//property[propertyName="ec_setup"]/value', 'ec_setup.pl'], 
	
	['//procedure[procedureName="DeployApp"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'parameterForms/cargoDeployForm.xml'],
	['//procedure[procedureName="UndeployApp"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'parameterForms/cargoUndeployForm.xml'],
	['//procedure[procedureName="RunContainer"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'parameterForms/cargoRunContainerForm.xml'],
	['//procedure[procedureName="StopContainer"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'parameterForms/cargoStopContainerForm.xml'],
	
);
