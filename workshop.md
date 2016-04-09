# VSTS and PaaS Workshop

## Exercise 1 - Create a VSTS instance with a web app in a Git repository

1. Go to the [VSTS homepage](https://www.visualstudio.com/en-us/products/visual-studio-team-services-vs.aspx)
2. Click on the "Get started for FREE" button, login with your Microsoft account and if you haven't already created a VSTS instance before then:
    * Fill out and submit the VSTS instance creation form; choose a URL and make sure to choose Git for the manage code option
    * ventually you will see "Your new team project **MyFirstProject** is now in the cloud."
    * Close that modal
3. If you already had a VSTS instance, but don't have a suitable project to work with then:
    * Go to the homepage of your tenant `https://{your_tenant}.visualstudio.com/`
    * Click New under "Recent projects & teams"
    * Type in a Project name, description (if you want) and ensure you select Git as the Version control and Click Create project
    * When it's done click Navigate to project and then close the modal that appears
4. Checkout the Git repository that was created:
    * Click on the "Code" tab
    * Clone the repository by either clicking on the "Clone in [IDE]" button or grabbing the repository link and using your favourite Git client
    * It should pop up a web-based login prompt for you to log in with your Microsoft account to authorise it assuming you have the latest version of Git for Windows
    * If it doesn't work you can either [download the latest version](https://git-scm.com/download/win) or [set up a personal access token](https://www.visualstudio.com/get-started/code/share-your-code-in-git-eclipse#pat) for your repository and use a traditional username and password
    * If you want the credentials to be securely stored so you don't need to keep getting prompted then install the [Git Credential Manager for Windows](https://github.com/Microsoft/Git-Credential-Manager-for-Windows)
    * You should now have an empty git repository checked out to your computer
5. Create an ASP.NET web project in Visual Studio 2015 that is stored in the same folder as your Git repository
    * By default that means you need to select the parent folder and name the solution the same as the folder of your Git checkout
    * Don't tick Application Insights for now (to simplify things)
    * Choose No Authentication and don't tick the "Host in the cloud" checkbox
    * Use the MVC template
6. Click save-all in Visual Studio, add a gitignore and commit the files then push up to origin/master
    * If you refresh the code tab in VSTS you should see your source code is there

Congratulations! You've created a VSTS instance with a Git repository containing a web application.

## Exercise 2 - Set up a Continuous Integration build

1. Create a default build definition:
    * Under the code tab in VSTS click on the "Build | Setup now" button
    * Select Visual Studio and hit "Next"
    * Ensure your repository is selected and `master` is the default branch, tick the "Continuous integration" checkbox and ensure you are using the "Hosted" agent queue (so you don't have to spin up a build server) then hit "Create"
2. Understand the build definition:
    * You should see a number of steps, it's worthwhile understanding what just happened
    * There will be a "NuGet Installer" step that automatically performs package restore on any Visual Studio solution files
    * There will be a "Visual Studio Build" step that automatically builds any Visual Studio solution files using a particular version of Visual Studio (currently 2015 by default) and for a platform and configuration from some [variables](https://msdn.microsoft.com/en-us/library/vs/alm/build/scripts/variables) `$(VariableName)`
    * There will be a "Visual Studio Test" step that automatically runs [VSTest](https://msdn.microsoft.com/en-us/library/ms182486.aspx) against any test dlls (`**\$(BuildConfiguration)\*test*.dll`)
    * There will be a "Index Sources & Publish Symbols" step that modifies `.pdb` files to [point the sources at the VSTS server](https://msdn.microsoft.com/en-us/Library/vs/alm/Build/steps/build/index-sources-publish-symbols)
    * There will be a "Copy Files" step that copies the files in the `bin\{Configuration}` directory to an artifacts staging directory
    * There will be a "Publish Build Artifacts" step that grabs the files from the artifacts staging directory and makes them an artifact of the build called "drop"
    * This setup is great for a Class Library that you want to publish the dlls for, but won't quite work for a web app
    * Click "Save", give the build a name and hit "OK"
    * Investigate the options in each of the tabs and try and understand what they do
    * Click on the "Builds" link at the top next to the build definition heading
    * Click on "Queue build..."
    * Click on "OK" (it should be Release and Any CPU by default"
    * Wait for the build to finish (you should have seen the build output as it ran - it's pretty cool!)
    * Click on the "Build {YYYYMMDD.#}" link at the top in the heading
    * Cick on the "Artifacts" tab - you should be able to see "drop"
    * Click on "Explore" and you will see it's blank - that's expected since it was looking for `bin\{Configuration}` whereas a web project only places binaries in `bin` directly
3. Tweak the build definition to be web friendly ([Reference](http://vsalmdocs.azurewebsites.net/library/vs/alm/release/getting-started/deploy-to-azure)):
    * Go to your build definition
    * Click on the "Edit" link in the heading
    * Under the "Visual Studio Build" step add the following to the "MSBuild Arguments" field: `/p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true` (this means that when the solution is built the web project will create a single zip file using Web Deploy)
    * Remove the "Index Sources & Publish Symbols" step since the files have already been added to the zip file at that point (you could still use it if you added a separate MSBuild call to generate the web deploy package rather than doing it at build time"
    * Change the "Copy Files" step so the "Contents" field now becomes `**\*.zip`
    * Click "Save" and then "OK"
    * Click "Queue build..." and then "OK"
    * Wait for the build to finish (you should have seen the build output as it ran - it's pretty cool!)
    * Click on the "Build {YYYYMMDD.#}" link at the top in the heading
    * Cick on the "Artifacts" tab - you should be able to see "drop"
    * Click on "Explore" and you will see the "drop" folder and a number of nested folders beneath it until eventually there is the zip file (feel free to download and explore the zip file)
4. Check that the continuous integration works:
    * Make a change to `Views\Home\Index.cshtml` in your web app in Visual Studio, commit the change and push it
    * In VSTS go to the build tab, click on your build definition on the left and go to the "Queued" tab (refresh until a build appears)
    * Double click on the build
    * You should see the build run automatically

Congratulations! You've set up Continuous Integration for your web application.

## Exercise 3 - Set up continuous deployment to an Azure Web App

1. Create an Azure Web App:
    * Go to the [Azure Portal](https://portal.azure.com/)
    * Click on "New" on the left menu
    * Click on "Web + Mobile"
    * Click on "Web App"
    * Enter a name for your app (end the name with "-test" since it will be a test environment)
    * Choose the correct subscription
    * Enter a new resource group name (use the same name as the web app, including the "-test")
    * Choose to create a new App Service plan: name if "{webappname_includingdashtest}-farm", choose to host in "Australia Southeast" and choose the "B1 Basic" tier, click "OK" 
    * Click "Create"
    * Wait for the deployment to finish and then inspect the web app in the Portal to get a feel for the capabilities in Azure Web Apps
2. Create Azure deployment credentials ([Reference](https://blogs.msdn.microsoft.com/visualstudioalm/2015/10/04/automating-azure-resource-group-deployment-using-a-service-principal-in-visual-studio-online-buildrelease-management/))
    * Figure out your subscription name by browsing to "Subscriptions" by the left menu in the Azure Portal and copying the name in the "Subscription" column
    * If you have an old version of Azure PowerShell then uninstall it (via "Add/Remove Programs" as well as anything in "C:\Program Files\WindowsPowerShell\Modules")
    * Use [Chocolatey](https://chocolatey.org/) to install [azurepowershell](https://chocolatey.org/packages/AzurePowerShell) (`choco install azurepowershell`)
    * [Download the script to create a service principal](https://raw.githubusercontent.com/Microsoft/vso-agent-tasks/master/Tasks/DeployAzureResourceGroup/SPNCreation.ps1)
    * Open a PowerShell prompt, `cd` to the folder with the script and run `.\SPNCreation.ps1 -subscriptionName "{Your_Subscription_Name}" -password "{Make_Up_A_Password}"`
    * You should see a bunch of information outputted - keep hold of that; you'll need it in a sec
3. Add Azure deployment credentials to VSTS
    * Go to VSTS and click on the cog icon in the top right toolbar ("Manage project")
    * Go to the "Services" tab
    * Click on "New Service Endpoint" and choose "Azure Resource Manager"
    * Enter a connection name that describes your Azure subscription
    * Add in the Subscription ID, subscription name, service principal id, service principal password and tenant ID that you got from the previous step
    * Note: at the time of writing you [can't seem use the Azure Resource Manager service endpoint](https://twitter.com/robdmoore/status/716602945542881280) to deploy a web app, so we will also need to create a Management Certificate based service endpoint (this is the old way of authentication to Azure) - don't worry, you will need the Azure Resource Manager service endpoint later in the workshop
        * Click on "New Service Endpoint" and choose "Azure Classic"
        * Choose the "Certificate Based" option
        * Add in a connection name
        * Click on the "publish settings file" link to create a management certificate and downloa a publish settings file
        * From the downloaded file extract the subscription id,  subscription name and string representing the management certificate and input it into VSTS and hit "OK"
4. Create a release definition that deploys your web app to the Azure Web App you created:
    * Go back to your VSTS project (prior to the "Manage project" cog)
    * Click on the "Release" tab
    * Click on the plus icon ("Create release definition")
    * Select "Azure Website Deployment" and click "OK"
    * Enter a name for the release definition
    * Click the cross icon to delete the Visual Studio test step (we don't need to run tests on deployment for this demo)
    * Select your subscription from the dropdown
    * Type in your web app name as per what you created in the above step
    * Choose the correct location that your web app was provisioned in
    * Remove the additional arguments
    * Click "Save"
    * Click on "Link to a buidl definition"
    * Select the CI build that you created earlier
    * Click "Save"
    * Go to the "Triggers" tab
    * Choose "Continuous Deployment", select the CI build and click "Save"
    * Go to the "Environments" tab and rename "Default Environment" to "Test"
    * Click on the "..." link for that environment and choose "Deployment conditions" and change the Trigger to "After release creation" and then click "OK" (this means that whenever a release is created the Test environment will auto-deploy)
    * Click "Save"
5. Deploy the release
    * Click on "[+] Release" and then "Create Release"
    * Select the latest version of your CI build and click "Create"
    * Click on the "Release-1" link that should have appeared to view the release
    * It should start automatically and show you the build log
    * You should now be able to visit your web app and see the deployed content
6. Trigger an automatic release
    * Make a change to `Views\Home\Index.cshtml` in your web app in Visual Studio, commit the change and push it
    * In VSTS go to the build tab, click on your build definition on the left and go to the "Queued" tab (refresh until a build appears)
    * Double click on the build
    * You should see the build run automatically
    * When it finishes, got to the "Release" tab and it should deploy automatically
    * When that finishes, visit the Azure Web App and it should be updated
    
Congratulations! You've set up continuous deployment for your web application.

## Exercise 4 - Create the test Azure environment using Azure Resource Manager from VSTS

1. [Download this repository](https://github.com/MRCollective/CDPipeline_MicrosoftAzureGlobalBootcampPerth2016/archive/master.zip)
2. Extract the files in the `exercise4` folder to a folder called `deploy` in your checked out Git repository
    * `Deploy.ps` is a PowerShell script that will create your environment - feel free to try and understand it
    * `azuredeploy.json` is an [Azure Resource Manager template deployment file](https://azure.microsoft.com/en-us/documentation/articles/resource-group-authoring-templates/) - it describes your environment (in this case a web app inside of an App Service server farm)
    * `Deploy-Local.ps1` is a PowerShell script that you can use for local debugging/development
3. If you want to run it locally to test it out then:
    * Open `Deploy-Local.ps1` and add values for the following empty variables: `$TenantId`, `$SubscriptionId`, `$AppName`
        * `$TenantId` can be found by clicking the `(?)` icon at the top right of the Azure Portal and selecting "Show diagnostics", hitting `Ctrl+F` on your keyboard and typing in "tenants" and grabbing the `id` property value (it will be a GUID) of the appropriate tenant
        * `$SubscriptionId` can be found by click on the "Subscriptions" entry on the left menu in the Azure Portal and copying the value in the "Subscription ID" column for the appropriate subscription (it will be a GUID)
        * `$AppName` will be the name of the app you created in Exercise 3
    * Open your `.gitignore` file ([create one](http://tutsheap.com/wiki/how-to-create-a-gitignore-file-in-windows/) in the root of your Git repository checkout if there isn't one) and add `profile.json` on it's own line somewhere in that file (this prevents you from being able to accidentally commit the access token that is stored when running `Deploy-Local.ps1`
    * Run `Deploy-Local.ps1` and it should work
    * If you have a name conflict with your previous deployment you should be able to safely delete the existing Resource Group first
4. Commit the new files and push them up
5. Add the deployment scripts as a build artifact in VSTS
    * Open the "Build" tab, click on the appropriate build definition and click the "Edit" link
    * Click on the "Publish Build Artifacts" step and click "Add build step", click on the "Utility" tab on the left and select "Publish Build Artifacts", click "Add" then click "Close"
    * Click on the new build step and enter:
        * "deploy" as "Path to Publish"
        * "deployment" as "Artifact Name"
        * "Server" as "Artifact Type"
    * Click "Save" and "OK"
6. Run the ARM deployment as part of the release definition
    * Open the "Release" tab, click on the appropriate release definition and click the "Edit" link
    * Click the "Add tasks" button, click on "Azure PowerShell", click "Add" then click "Close"
    * Click on the new deployment step and:
        * Choose "Azure Resource Manager" as "Azure Connection Type"
        * Select the "Azure RM Subscription" you created earlier
        * Click the "..." for "Script Path" and navigate to `Deploy.ps1`
        * Enter the following for "Script Arguments": `-AlreadyLoggedIn -TenantId (Get-AzureRmContext).Tenant.TenantId -SubscriptionId (Get-AzureRmContext).Subscription.SubscriptionId -Location "Australia Southeast" -AppName "$(AppName)" -AppEnvironment "$(AppEnvironment)"`
        * Drag the new release step to run before the web app deployment
        * Click "Save"
        * Go to the "Configuration" tab
        * Enter a new variable "AppName" with the name of the app you created in Exercise 3
        * Go back to the "Environments" tab, click the "..." icon on the "Test" environment and click "Configure variables"
        * Remove all the variables that are there by default and add a new one called "AppEnvironment" and set the value to "test" and click "OK"
        * Click "Save"
    * Go to the build tab, select the appropriate build definition and click the "Queue build..." button and click "OK"
    * Wait for the build to complete, then click on the "Release" tab and double click on the new release that was created and click on the "Logs" tab to see the release logs
    * Feel free to try deleting the resource group from Azure and re-running a deployment to ensure that it works

Congratulations! You've automatically created an Azure environment from VSTS.

## Exercise 5 - Add production deployment

1. Add the production environment
    * Go to the "Release" tab in VSTS, find the relevant release definition and click "Edit"
    * Click on the "Azure Web App Deployment" task and change the web app name to `$(AppName)-$(AppEnvironment)`
    * Click on the "..." button for the "Test" environment and select "Clone environment"
    * Type in "Production" and hit enter
    * Click on the "..." button for the "Production" environment and select "Configure variables"
    * Change the "AppEnvironment" variable value to "prod" and click "OK"
    * Click on the "..." button for the "Production" environment and select "Deployment conditions"
    * Change the "Trigger" to "No automated deployment" and click "OK"
    * Click "Save" 
2. Instigate a production deployment
    * Click the "Releases" link next to the release definition title
    * Click "Release" and then "Create Release"
    * Select the last successful CI build and then click "Create"
    * The new release should show up and should have two grey bars to indicate the fact there are now two environments
    * Double click the release to see the details
    * When the release has finished click "Deploy" and then select "Production" and then click "Deploy"
    * Click on the "Logs" tab to see the progress of the production deployment
    * When the build has finished check in the Azure portal to see if a new web app was created for production and visit it to ensure the application was successfully deployed
3. Look at the build pipeline view
    * Go to the "Release" tab and click on the "Overview" tab
    * Observe the visualisation - this shows what version is deployed to what environment at any time

Congratulations! You have created a production environment that matches your test environment exactly and deployed to it all from VSTS.

## Further exercises

The following exercises are left to the reader to complete to try and extend the work they have done.

* Add proper version numbers by adding [GitVersion](https://marketplace.visualstudio.com/items?itemName=gittools.gitversion) as the first step of the CI build (including updating assembly info), changing build number format to be `$(Build.BuildNumber)` and labelling on successful build with the value `$(GitVersion_SemVer)` so the version increments on each successful build. Change the version number in the release definition to `$(Build.BuildNumber)`. Output `@typeof(MvcApplication).Assembly.GetName().Version` in the footer of the site so you can verify what version is deployed to which environment.
* Change the `azuredeploy.json` file to change [properties of your web app](https://github.com/davidebbo/AzureWebsitesSamples/blob/master/ARMTemplates/WebAppManyFeatures.json) (e.g. the always on setting) and propagate that change through your test and production environment (checking it worked via the Azure Portal).
* Add an [Azure SQL Database](https://github.com/Azure/azure-quickstart-templates/blob/master/201-web-app-sql-database/azuredeploy.json) to the `azuredeploy.json` file and change the connection string for the web app to point to it and use the connection from your code. 
