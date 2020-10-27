Get Traffic Manager Endpoint Health
===================================

            

Powershell code with two helper functions and function that is checking the health of the traffic manager endpoints.


**1. Function Find-EmptyString **- Just a nice way of handling the variables that are empty with the custom output message.


**2. Function Confirm-AzSession **- Piece of code that will check if your Powershell session has currently being authenticated against any Azure tenant/subscription.


**3. Function Get-AzTrafficManagerEndpointHealth **- The main function which will query the traffic manager and all its endpoints or just a specific endpoint from the TM.


 


**Requirements:**


This function is using a subset f Az.* modules, make sure to install them previously.


**Example:**


** **

** **




        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
