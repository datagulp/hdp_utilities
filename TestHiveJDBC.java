package com.ganeshrj.jdbcconn.test;

import java.sql.*;  

public class TestHiveJDBC { 
	
	  public static void main(String[] args) throws SQLException { 
		  
			System.out.println("-------- HiveServer2 JDBC Connection Testing ------");
			
			  String driverName = "org.apache.hive.jdbc.HiveDriver";
			//System.out.println("Connection String " + Connection_String + "Connection Username " + Connection_UserName + 
				//	       " Query String : " + Connection_QueryString );
			
			System.out.println (" No of args passed : " + args.length);
			
			
			/* Uncomment below for actual code */ 
			 
			if (args.length > 0  && args.length < 5) { 
			
			String Connection_String=args[0];
		    String Connection_UserName=args[1];
			String Connection_PassWord=args[2];
			String Connection_QueryString=args[3];
           
			
		    // Test Stub below
			/*	
			
			if (args.length == 0 )  { 

				 
				
				String Connection_String="jdbc:hive2://grj-7.field.hortonworks.com:10000/default";
				String Connection_UserName="hive" ;
				String Connection_PassWord="";
				String Connection_QueryString="select * from test5";
				
		     */
			
			
				System.out.println("Connection String  : " + Connection_String + "\nConnection Username : " + Connection_UserName + 
					       " \nQuery String : " + Connection_QueryString );
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

					//connection = DriverManager.getConnection(
					//		"jdbc:oracle:thin:@localhost:1521/serviceid", "username",
					//		"password");
					
					System.out.println ( " Acquiring DB Connection .... "); 
					
					connection = DriverManager.getConnection(Connection_String,Connection_UserName, Connection_PassWord);
					
					

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
				System.out.println(" Ensure the args are passed in order as follows : Connection_String , Connection_Username , Connection_Password,  Connection_QueryString");
			}
	  }
}
