// Code to test out Quick Oracle JDBC connectivity

package com.ganeshrj.jdbcconn.test;

import java.sql.*;  

public class JDBCConn { 
	
	  public static void main(String[] args) { 
		  
			System.out.println("-------- Oracle JDBC Connection Testing ------");
			
			
			//System.out.println("Connection String " + Connection_String + "Connection Username " + Connection_UserName + 
				//	       " Query String : " + Connection_QueryString );
			
			System.out.println (" No of args passed : " + args.length);
			
			if (args.length > 0 && args.length < 7) { 
				

				String Connection_String=args[0];
				String Connection_UserName=args[1];
				String Connection_PassWord=args[2];
				String Connection_QueryString=args[3];
				int RepeatCount=Integer.parseInt(args[4]);
				long SleepTime=Long.parseLong(args[5]);
				
				System.out.println("Connection String  : " + Connection_String + "\nConnection Username : " + Connection_UserName + 
					       " \nQuery String : " + Connection_QueryString + " \nRepeat Count :  " + RepeatCount + " \n Sleep Count : " + SleepTime);
				try {

					Class.forName("oracle.jdbc.driver.OracleDriver");

				} catch (ClassNotFoundException e) {

					System.out.println("Where is your Oracle JDBC Driver?");
					e.printStackTrace();
					return;

				}

				System.out.println("Oracle JDBC Driver Registered!");

				Connection connection = null;

				try {

					//connection = DriverManager.getConnection(
					//		"jdbc:oracle:thin:@localhost:1521/serviceid", "username",
					//		"password");
					
					System.out.println ( " Acquiring DB Connection .... "); 
					
					connection = DriverManager.getConnection(Connection_String,Connection_UserName, Connection_PassWord);
					
					String vendorName = connection.getMetaData().getDatabaseProductName() + connection.getMetaData().getDatabaseMajorVersion() + connection.getMetaData().getDatabaseMajorVersion();
					
					System.out.println (" Vendor name : " + vendorName); 
		 

				} catch (SQLException e) {

					System.out.println("Connection Failed! Check output console");
					e.printStackTrace();
					return;

				}

				if (connection != null) {
					System.out.println("Oracle JDBC Connection Successful... ");
					
					String qryString = Connection_QueryString;
					
					
					Statement stmt=null;
					try {
						
						for (int rptcount=1;rptcount<=RepeatCount;rptcount++) { 
							
							System.out.println("Getting connection again !!! " + rptcount);
							
							connection.close();
							connection = DriverManager.getConnection(Connection_String,Connection_UserName, Connection_PassWord);
							
							System.out.println(" Query Exec Cycle ... " + rptcount);
							
							stmt = connection.createStatement();
							ResultSet rows = stmt.executeQuery(qryString);
							
							ResultSetMetaData metadata = rows.getMetaData();
							int columnCount = metadata.getColumnCount();  
							
							int count=0;
					        while (rows.next()) {
					                count+=1;
					                String row = "";
					                for (int i = 1; i <= columnCount; i++) {
					                    row += rows.getString(i) + ", ";          
					                } 
					                System.out.println("Row #:"+count + "Rows : " +row);
		
					                }

							if (count == 0) { 
								
								System.out.println("No records found ... ");
							}
							Thread.sleep(SleepTime);
						}
						
					    connection.close();
					} catch (SQLException e1) {
						System.out.println( " Unable to get Run the query .... ");
						e1.printStackTrace();
					} catch (InterruptedException e) {
						System.out.println( " Thread Intrerruption .... ");
						e.printStackTrace();
					}
					
				 
				} else {
					System.out.println("Failed to make connection!");
				}				
			}
			else { 
				System.out.println(" Please pass valid args ... " );
				System.out.println(" Ensure the args are passed in order as follows : Connection_String , Connection_Username , Connection_Password,  Connection_QueryString,  RepeatCount  AND SleepTime");
			}
	  }
}
