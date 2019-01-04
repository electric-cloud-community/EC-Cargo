
push (@::gMatchers,
  
  {
   id =>        "undeploySucces",
   pattern =>          q{BUILD SUCCESS},
   action =>           q{
    
              my $description .= "Application undeployed successfuly";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },
  
  {
   id =>        "undeployFailed",
   pattern =>          q{(.*)The username and password you provided are not correct(.*)},
   action =>           q{
    
              my $description = "The username and password provided are not correct";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
  {
   id =>        "undeployPathNonExist",
   pattern =>          q{(.*)Cannot open file(.*)},
   action =>           q{
    
              my $description = "The path provided do not exist";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  

  {
   id =>        "undeployContainerFail",
   pattern =>          q{(.*)Connection timed out(.*)},
   action =>           q{
    
              my $description = "The container is not responding";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
  {
   id =>        "undeployContainerHomeDontExist",
   pattern =>          q{The home path of the container do not exist},
   action =>           q{
    
              my $description = "The home path of the container do not exist";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
  {
   id =>        "undeployAppDontExist",
   pattern =>          q{Failed to undeploy as there is no WAR},
   action =>           q{
    
              my $description = "Application context WAR not found";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },    
  {
   id =>        "undeployRemoteNotSupported",
   pattern =>          q{WebLogic remote undeploy not supported},
   action =>           q{
    
              my $description = "WebLogic remote undeploy not supported";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },      
  {
   id =>        "undeployRemoteNotSupported",
   pattern =>          q{Jetty undeploy not supported},
   action =>           q{
    
              my $description = "Jetty undeploy not supported";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
);

