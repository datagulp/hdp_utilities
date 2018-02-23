package com.ganeshrj.hive.jdbcTest;


/* This code mimics the Hive Beeline command to run Queries from Extended system... 
 * 
 * Sample String: 
 * java -jar HiveJDBCConnKrb.jar "jdbc:hive2://grj-3.field.hortonworks.com:10000/default;principal=hive/_HOST@GANESHRJ.COM?hive.execution.engine=tez" "ambari-qa-hdp228@GANESHRJ.COM" "/etc/security/keytabs/smokeuser.headless.keytab" "select distinct a  from hivetest.test1"
 * 
 * Copyright @ Ganesh Rajagopal  
 */


import java.io.IOException;
import java.sql.*;
import java.util.Scanner;

import javax.security.auth.Subject;
import javax.security.auth.callback.*;
import javax.security.auth.callback.UnsupportedCallbackException;
import javax.security.auth.login.LoginContext;
import javax.security.auth.login.LoginException;
import org.apache.hadoop.security.*;
import org.apache.hadoop.conf.*;
 


public class TestHiveJDBCKrb { 
	
	 
	static String driverName = "org.apache.hive.jdbc.HiveDriver";
	static String Current_UserPrincipal="";
	static String User_password=""; 
	static String Connection_Principal;
	static String Connection_Keytab;
	static String Connection_String;
	static String Connection_QueryString;
  
    public static class MyCallbackHandler implements CallbackHandler {

        private Scanner reader;
        
		public void handle(Callback[] callbacks)
                throws IOException, UnsupportedCallbackException {
        
            for (int i = 0; i < callbacks.length; i++) {
                if (callbacks[i] instanceof NameCallback) {
                    NameCallback nc = (NameCallback) callbacks[i];
                    System.out.println("Enter User Principal. Can be obtained from Kinit : ");
                     
                    Current_UserPrincipal = reader.next();
                    nc.setName(Current_UserPrincipal);
                } else if (callbacks[i] instanceof PasswordCallback) {
                    PasswordCallback pc = (PasswordCallback) callbacks[i];
                    System.out.println("Enter the AD/LDAP password: ");
                    java.io.Console console = System.console();
                    User_password = new String(console.readPassword("Enter the password for " +  Current_UserPrincipal  + " : " ));
                    pc.setPassword(User_password.toCharArray());
                } else throw new UnsupportedCallbackException
                        (callbacks[i], "Unrecognised callback");
            }
        }
    }
    
     
   
   public static Subject kinit()  {
     
	   Subject CurrentUserSubject = null;
	 
	   try {
	    	   LoginContext lc = new LoginContext("TestHiveJDBCKrb", new MyCallbackHandler());
     	  
	    	   lc.login();
	    	    CurrentUserSubject = lc.getSubject(); 
		} catch (LoginException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			System.exit(1);
		}
	   
	   return CurrentUserSubject; 
	   
   }
	
   
	public static void main(String[] args) throws SQLException { 
		  
			System.out.println("-------- HiveServer2 JDBC Connection Testing (Kerberos)  ------");
			
			// Get the Kerb JAAS Config loaded. 
			
			System.setProperty("java.security.auth.login.config", "TestHiveJDBCKrb.config");

						
			System.out.println (" No of args passed : " + args.length);
			
			if (args.length < 2 ) { 
				System.out.println("Need atleast 2 arguments - Connection Information and Query String. Note that Principal and Keytabs are optional");
				
				System.out.println("Sample Input String Below : ");
				System.out.println("=========================== ");
				
				System.out.println("java -jar HiveJDBCConnKrb.jar \"jdbc:hive2://<HS2 Host>:10000/<db>;principal=hive/_HOST@REALM.COM?hive.execution.engine=tez\"  \"Query String\" \"principal@REALM.COM\" \"keytab file\"");
			}
			
			
			if (args.length == 2 ) { 
            	
	      	     System.out.println("***********************");
	             System.out.println("Echoing Input Parms ");
	           	 
	   			 System.out.println("Arg 1 :  " + args[0]);
	   			 System.out.println("Arg 2 :  " + args[1]);
	      	     System.out.println("***********************");
			}
			
			else { 
				try { 
	            	
		      	     System.out.println("***********************");
		             System.out.println("Echoing Input Parms ");
		           	 
		   			 System.out.println("Arg 1 :  " + args[0]);
		   			 System.out.println("Arg 2 :  " + args[1]);
		   			 System.out.println("Arg 3 :  " + args[2]);
		   			 System.out.println("Arg 4 :  " + args[3]);
		   			 
		   			 System.out.println("***********************");
		          	 
		            }
				  	 catch (ArrayIndexOutOfBoundsException e) { 
				  		 System.out.println( " Invalid Arguments Entered. Missing Principal or Keytab !!! ");
				  		 
						 System.out.println("Sample Input String Below : ");
						 System.out.println("=========================== ");
							
							
				  		 System.out.println("java -jar HiveJDBCConnKrb.jar \"jdbc:hive2://<HS2 Host>:10000/<db>;principal=hive/_HOST@REALM.COM?hive.execution.engine=tez\"  \"Query String\" \"principal@REALM.COM\" \"keytab file\"   \"principal\" \"keytab file \"");
						 System.exit(1);
				  	 }
				
			}
            
			 
			/* Uncomment below for actual code */ 
            
            
			if (args.length > 0  && args.length <= 4) { 
					
					 Connection_String=args[0].trim();
					 Connection_QueryString=args[1].trim();
					
					if (args.length > 2) { 
						
						try { 
						     Connection_Principal=args[2].trim();
							 Connection_Keytab=args[3].trim();
						}
						catch (ArrayIndexOutOfBoundsException e) { 
					  		 System.out.println( " Invalid Arguments Entered. Check argument 3 & 4 ... " + args.length);
							 System.exit(1);
					  	 }
					}
 
		    // Test Stub below
			
			/*
			if (args.length == 0 )  { 

				String Connection_String="jdbc:hive2://grj-3.field.hortonworks.com:10000/default;principal=hive/_HOST@GANESHRJ.COM?hive.execution.engine=tez";
				//String Connection_UserName="" ;
				//String Connection_PassWord="";
				String Connection_Principal="ambari-qa-hdp228@GANESHRJ.COM";
				String Connection_Keytab="/Users/grajagopal/Downloads/smokeuser.headless.keytab";	
				//String Connection_Principal="";
				//String Connection_Keytab="";		
				String Connection_QueryString="select count(*)  from hivetest.test1";
				*/
		     
					
				System.out.println(" NOTE:- If the principal and Keytabs are not Passed, the User credential will be Requested ");
		           
				System.out.println("Connection String : " + Connection_String + "  Connection Principal (Optional) : " + Connection_Principal + "  Connection Keytab  (Optional) : " + Connection_Keytab + 
						       " Query String : " + Connection_QueryString );
					
								
				Configuration conf = new  Configuration(); //From org.apache.hadoop.conf
	            conf.set("hadoop.security.authentication", "kerberos");
	        
	            UserGroupInformation.setConfiguration(conf);
	            
	            
	            if ((Connection_Keytab == null || Connection_Keytab.isEmpty()) && (Connection_Principal == null || Connection_Principal.isEmpty())) { 

	            	try {
		            	//First try logging in using the Credential Cache if not go for asking creds. 
	            		System.out.println("Using Current User Creds Cache: " + UserGroupInformation.getCurrentUser());
						UserGroupInformation.loginUserFromSubject(null);
					} catch (IOException e1) {
						// TODO Auto-generated catch block
						//e1.printStackTrace();
		            	Subject sub = kinit(); 
		            	try {
							UserGroupInformation.loginUserFromSubject(sub);
						} catch (IOException e) {
			 
							e.printStackTrace();
						}
					}

	            	}
	            	
	            else {
			    	try {
			 			    		
			    		UserGroupInformation.loginUserFromKeytab(Connection_Principal, Connection_Keytab);
			    		
					} catch (IOException e1) {
						// TODO Auto-generated catch block
						e1.printStackTrace();
					}
	            }	
		             					       								
				try {

					Class.forName(driverName);

				} catch (ClassNotFoundException e) {

					System.out.println("Hive JDBC driver class not found.");
					e.printStackTrace();
					return;

				}

				System.out.println("Hive JDBC Driver Registered!");

				Connection connection = null;

				try {

					System.out.println ( " Acquiring DB Connection .... "); 
					
					connection = DriverManager.getConnection(Connection_String);

				} catch (SQLException e) {

					System.out.println("Connection Failed! Check output console");
					e.printStackTrace();
					return;

				}
					
			 
				if (connection != null) {
					System.out.println ("HiveServer2  JDBC Connection Successful... ");
					
					System.out.println("Listing Existing Databases :  ");
					Statement stmt = connection.createStatement();
					ResultSet res = stmt.executeQuery("show databases");
				      while (res.next()) {
				        System.out.println(res.getString(1));
				      }
					String qryString = Connection_QueryString;

					System.out.println(" Executing the Input Query : " + qryString);
					
					ResultSet res1=stmt.executeQuery(qryString);
					
					
					ResultSetMetaData metadata = res1.getMetaData();
					int columnCount = metadata.getColumnCount();  
					
					int count=0;
			        while (res1.next()) {
			                count+=1;
			                String row = "";
			                for (int i = 1; i <= columnCount; i++) {
			                    row += res1.getString(i) + " | ";          
			                } 
			                System.out.println("Row #:"+count + " Recs : " +row);

			                }

					if (count == 0) { 
						
						System.out.println("No records found ... ");
					}
					
					 
				}
			
			connection.close();
				 				
			}
			else { 
				System.out.println(" Please pass valid args ... " );
				System.out.println(" Ensure the args are passed in order as follows : Connection_String , Connection Principal (Optional), Connection Keytab (Optional),  Connection_QueryString");
				System.out.println(" NOTE: If the Principals and keytabs are not passed the code will request for the User Credentials " );
				 
			}
	  }
 
}
