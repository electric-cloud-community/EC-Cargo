	# -------------------------------------------------------------------------
	# File
	#    CargoConfigs.pl
	#
	# Dependencies
	#    None
	#
	# Template Version
	#    1.0
	#
	# Date
	#    03/16/2012
	#
	# Engineer
	#    Rafael Sanchez
	#
	# Copyright (c) 2012 Electric Cloud, Inc.
	# All rights reserved
	# -------------------------------------------------------------------------
	
	package CargoCommon;
	use strict;

	use constant {
	
		SUCCESS => 0,
		ERROR   => 1,
		
		
		WIN_IDENTIFIER => 'MSWin32',	   
		CREDENTIAL_ID => 'credential',

		SQUOTE => q{'},
		DQUOTE => q{"},
		BSLASH => q{\\},

		   
		LOCAL => "local",
		REMOTE => "remote",
		
		TOMCAT6X_TYPE => "tomcat6x",
		TOMCAT6X_CONFIG => "<id>tomcat6x</id>
	  <build>
		<pluginManagement>
		  <plugins>		  
			<plugin>
			  <groupId>org.codehaus.cargo</groupId>
			  <artifactId>cargo-maven2-plugin</artifactId>
	
			  <configuration>
				<container>
				  <containerId>tomcat6x</containerId>
				  <type>_deployType_</type>
				  <home>_selectedContainer_</home>
				</container>
				  
				<configuration>
				  <type>_configType_</type>
				  <home>_selectedContainer_</home>
				  <properties>
					<cargo.remote.username>_tomcatUser_</cargo.remote.username>
					<cargo.remote.password>_tomcatPass_</cargo.remote.password>
                    <cargo.remote.uri>_url_</cargo.remote.uri>
				  </properties>
				</configuration>

				<deployer>
				  <type>_deployType_</type>
				  <deployables>
					<deployable>
					  <groupId>_groupId_</groupId>
					  <artifactId>_artifactId_</artifactId>
					  <type>war</type>        
                      <properties>
                        <context>_contextPath_</context>
                      </properties>
					</deployable>
				  </deployables>
				</deployer>
			  </configuration>                
			</plugin>			  
		  </plugins>
		</pluginManagement>
	  </build>",
		
		
		JETTY8X_TYPE => "jetty8x",
		JETTY8X_CONFIG => "<id>jetty8x</id>
	  <build>
		<pluginManagement>
		  <plugins>		  
			<plugin>
			  <groupId>org.codehaus.cargo</groupId>
			  <artifactId>cargo-maven2-plugin</artifactId>
	
			  <configuration>
				<container>
				  <containerId>jetty8x</containerId>
				  <type>_deployType_</type>
				  <home>_selectedContainer_</home>
				</container>
				  
				<configuration>
				  <type>_configType_</type>
				  <home>_selectedContainer_</home>
				  <properties>
					<cargo.remote.username>_jettyUser_</cargo.remote.username>
					<cargo.remote.password>_jettyPass_</cargo.remote.password>
					<cargo.hostname>_jettyHost_</cargo.hostname>
					<cargo.servlet.port>_jettyPort_</cargo.servlet.port>
				  </properties>
				</configuration>

				<deployer>
				  <type>_deployType_</type>
				  <deployables>
					<deployable>
					  <groupId>_groupId_</groupId>
					  <artifactId>_artifactId_</artifactId>
					  <type>war</type>        
                      <properties>
                        <context>_contextPath_</context>
                      </properties>
					</deployable>
				  </deployables>
				</deployer>
			  </configuration>                
			</plugin>			  
		  </plugins>
		</pluginManagement>
	  </build>",
		
		
		
		JBOSS7X_TYPE => "jboss7x",
		JBOSS7X_CONFIG => "<id>jboss7x</id>
	  <build>
		<pluginManagement>
		  <plugins>		  
			<plugin>
			  <groupId>org.codehaus.cargo</groupId>
			  <artifactId>cargo-maven2-plugin</artifactId>
	
			  <configuration>
				<container>
				  <containerId>jboss7x</containerId>
				  <type>_deployType_</type>
				  <home>_selectedContainer_</home>
				</container>
				  
				<configuration>
				  <type>_configType_</type>
				  <home2>_selectedContainer_</home2>
				  <properties>
					<cargo.remote.username>_jbossUser_</cargo.remote.username>
					<cargo.remote.password>_jbossPass_</cargo.remote.password>
					<cargo.hostname>_jbossHost_</cargo.hostname>
					<cargo.servlet.port>_jbossPort_</cargo.servlet.port>
				  </properties>
				</configuration>

				<deployer>
				  <type>_deployType_</type>
				  <deployables>
					<deployable>
					  <groupId>_groupId_</groupId>
					  <artifactId>_artifactId_</artifactId>
					  <type>war</type>        
                      <properties>
                        <context>_contextPath_</context>
                      </properties>
					</deployable>
				  </deployables>
				</deployer>
			  </configuration>  
			  <dependencies>
				<dependency>
				  <groupId>org.jboss.as</groupId>
				  <artifactId>jboss-as-controller-client</artifactId>
				  <version>7.0.2.Final</version>
				</dependency>
			  </dependencies>              
			</plugin>			  
		  </plugins>
		</pluginManagement>
	  </build>",
		
		
		WEBLOGIC10X_TYPE => "weblogic103x",
		WEBLOGIC10X_CONFIG => "<id>weblogic103x</id>
	  <build>
		<pluginManagement>
		  <plugins>		  
			<plugin>
			  <groupId>org.codehaus.cargo</groupId>
			  <artifactId>cargo-maven2-plugin</artifactId>
	
			  <configuration>
				<container>
				  <containerId>weblogic103x</containerId>
				  <type>_deployType_</type>
				  <home2>_selectedContainer_</home2>
				</container>
				  
				<configuration>
				  <type>_configType_</type>
				  <home>_selectedContainer_</home>
				  <properties>
					<cargo.weblogic.server>_weblogicHost_</cargo.weblogic.server>
					<cargo.servlet.port>_weblogicPort_</cargo.servlet.port>
					<cargo.weblogic.administrator.user>_weblogicUser_</cargo.weblogic.administrator.user>
					<cargo.weblogic.administrator.password>_weblogicPass_</cargo.weblogic.administrator.password>
				  </properties>
				</configuration>

				<deployer>
				  <type>_deployType_</type>
				  <deployables>
					<deployable>
					  <groupId>_groupId_</groupId>
					  <artifactId>_artifactId_</artifactId>
					  <type>war</type>        
                      <properties>
                        <context>_contextPath_</context>
                      </properties>
					</deployable>
				  </deployables>
				</deployer>
			  </configuration>              
			</plugin>			  
		  </plugins>
		</pluginManagement>
	  </build>",
	};
	 
1;
