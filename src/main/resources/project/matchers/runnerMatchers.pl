
push (@::gMatchers,
  
  {
   id =>        "runSucces",
   pattern =>          q{The container is running.},
   action =>           q{
    
              my $description .= "The container is running";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },
  
  {
   id =>        "runFailed",
   pattern =>          q{Error starting the container.},
   action =>           q{
    
              my $description = "Error starting the container";
                              
              setProperty("summary", $description . "\n");
    
   },  
  }, 
  
  {
   id =>        "runRemoteFailed",
   pattern =>          q{Only local containers can be started},
   action =>           q{
    
              my $description = "Only local containers can be started";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
  {
   id =>        "runLocalFailed",
   pattern =>          q{Jetty run local container not supported},
   action =>           q{
    
              my $description = "Jetty run local container not supported";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  

);

