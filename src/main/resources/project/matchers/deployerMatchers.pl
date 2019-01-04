
push (@::gMatchers,
  
  {
   id =>        "deploySucces",
   pattern =>          q{BUILD SUCCESS},
   action =>           q{
    
              my $description .= "Application deployed successfuly";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },
  
  {
   id =>        "deployFailed",
   pattern =>          q{(.*)The username and password you provided are not correct(.*)},
   action =>           q{
    
              my $description = "The username and password provided are not correct";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
  {
   id =>        "deployPathNonExist",
   pattern =>          q{(.*)Cannot open file(.*)},
   action =>           q{
    
              my $description = "The path provided do not exist";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  

  {
   id =>        "deployContainerFail",
   pattern =>          q{(.*)Connection timed out(.*)},
   action =>           q{
    
              my $description = "The container is not responding";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
  {
   id =>        "deployContainerHomeDontExist",
   pattern =>          q{The home path of the container do not exist},
   action =>           q{
    
              my $description = "The home path of the container do not exist";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
  {
   id =>        "deployRemoteNotSupported",
   pattern =>          q{WebLogic remote deploy not supported},
   action =>           q{
    
              my $description = "WebLogic remote deploy not supported";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },    
  {
   id =>        "deployRemoteNotSupported",
   pattern =>          q{Jetty remote deploy not supported},
   action =>           q{
    
              my $description = "Jetty remote deploy not supported";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
);

