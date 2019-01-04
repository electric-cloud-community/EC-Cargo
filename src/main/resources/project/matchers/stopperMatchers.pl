
push (@::gMatchers,
  
  {
   id =>        "stopSucces",
   pattern =>          q{The container is not running.},
   action =>           q{
    
              my $description .= "The container is not running";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },
  
  {
   id =>        "stopFailed",
   pattern =>          q{The container is still running.},
   action =>           q{
    
              my $description = "The container is still running";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
  
  {
   id =>        "stopRemoteFailed",
   pattern =>          q{Only local containers can be stopped},
   action =>           q{
    
              my $description = "Only local containers can be stopped";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  

  {
   id =>        "stopLocalFailed",
   pattern =>          q{Jetty stop container not supported},
   action =>           q{
    
              my $description = "Jetty stop container not supported";
                              
              setProperty("summary", $description . "\n");
    
   },  
  },  
);

