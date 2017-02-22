# Custom Continuous Deployment Script(Kudu) for Nodejs app on Azure

## A little History
* I have a `node.js` application
* The application have front-end application too (angular SPA using ES5 js)
* The project setup uses `bower` to resolve client dependancy packages
* The project setup uses `gulp` to automate build processes of different environments _(including minification & file concatination etc)_
* Using gulp task in gulpfile.js, I can package **complete** font-end app into `dist` folder for dev, staging and production versions

## End Goal
* I want to setup Continuous Deployment into Azure App Service from git `master` branch
* I want to build front-end application on production version using Custom Deployment script when there is a push
* Deploy the build output i.e `dist` folder into `wwwroot`. **Only** the `dist` folder _(which has complete external library as well as application code in it)_
* Deploy the `node.js` application into `wwwroot`

## A little concept of Kudu
It is [open source](https://github.com/projectkudu) and it is an engine behind the source control based deployment in Microsoft Azure. It can deploy from Git, dropbox and many more. Typically we can deploy application in three ways
* FTP deployment
* Web deployment which is usually done from Visual Studio
* Kudu based deployment

Whenever you create a Azure website regardless of you choose Kudu based deployment or not, Kudu is automatically available. Also it creates a companion kude site. You can open kudu site with https://_yoursitename_.scm.azurewebsites.net also known as SCM. The kudu site provide many feature of application insight (which I am not covering here).

According to the type of project either it is asp.net site or node js site or other platform's site kudu has a corresponding default script which run when you configured continous deployment from supported source controls. This default script can be downloaded from Azure site and customize it _(And this article is all about)_

Refer following short videos of Scott Hanselman with David Ebbo about kudu
* [What is Kudu? - Azure Friday](https://www.youtube.com/watch?v=_fhmUqNGz2Y) 
* [Deploying to Web Sites with GitHub using Kudu - Azure Friday](https://www.youtube.com/watch?v=kE0qNV2UBmA) 
* [Custom Web Site Deployment Scripts with Kudu](https://www.youtube.com/watch?v=FI1PfFVquKo)
* [Exploring the Super Secret Kudu Debug Console - Azure Friday](https://www.youtube.com/watch?v=-VjqyvA2XjM) 

I hope you get enough basics of Kubu by now. Let's move to implimentation

## Custom Deployment Script for Nodejs Project
To download or get default kudu script into your local repository you need to install Azure CLI

```npm install azure-cli -g```

To download default kudu build script for node js project run following command

```azure site deploymentscript --node``` 

It will create two files in you directory `.deployment` & `deploy.cmd`. **Don't be afraid of scripts in deploy.cmd**. Just focus this will be **going to ease my life** a lot.

Now let's replace the script deploy.cmd from this repository and walk through it. Nothing much has been changed don't worry

## Another understanding before script walk through
* Most probable folder structure of your Azure website is
    * D:\home\LogFiles
    * D:\home\site\deployments 
    * D:\home\site\diagnostics
    * D:\home\site\locks
    * D:\home\site\repository
    * D:\home\site\wwwroot
* When you configured Continous Deployment in Azure website, the complete repository from the source control will be copied to repository folder above
* Deployment related logs (like when last deployed and what & where files are deployed) will be in deployments folder above
* Application error log will be in LogFiles above
* The running live code will be in wwwroot folder above. **The code here should be output of Custom build script**

Too much of basic now, now let's really walk through the script

## Script walk through

``` 
echo "-----------------Variables---------------------------------"
echo "DEPLOYMENT_SOURCE = %DEPLOYMENT_SOURCE%"
echo "DEPLOYMENT_TARGET = %DEPLOYMENT_TARGET%"
echo "NEXT_MANIFEST_PATH = %NEXT_MANIFEST_PATH%"
echo "PREVIOUS_MANIFEST_PATH = %PREVIOUS_MANIFEST_PATH%"
echo "KUDU_SYNC_CMD = %appdata%\npm\kuduSync.cmd"
echo "-----------------Variables END ---------------------------------"
echo ""
echo "" 
```

Prety obvious, variables used in the script. But knowing value is very important
* DEPLOYMENT_SOURCE = _D:\home\site\repository_
* DEPLOYMENT_TARGET = _D:\home\site\wwwroot_
* NEXT_MANIFEST_PATH = _D:\home\site\deployments\some unique id\manifest_
* PREVIOUS_MANIFEST_PATH = _D:\home\site\deployments\some unique id\manifest_
* KUDU_SYNC_CMD = _D:\local\AppData\npm\kuduSync.cmd_

```
:: 2. Install npm devDependancy packages with explicit flag --only=dev at DEPLOYMENT_SOURCE instead of DEPLOYMENT_TARGET
echo =======  Installing npm  devDependancy packages: Starting at %TIME% ======= 
IF EXIST "%DEPLOYMENT_SOURCE%\package.json" (
  pushd "%DEPLOYMENT_SOURCE%"
  call :ExecuteCmd !NPM_CMD! install --only=dev
  IF !ERRORLEVEL! NEQ 0 goto error
  popd
)
echo =======  Installing npm dev packages: Finished at %TIME% ======= 
```

Intalling dev dependancy packages defined in `package.json` which will be required for building and running gulp task. The `--only=dev` says to install only those packages which are defined in `devDependancies` only. See related [issue](https://github.com/projectkudu/kudu/issues/2239) in kudu project.
Also notice that it is searching package.json in DEPLOYMENT_SOURCE folder not in DEPLOYMENT_TARGET folder which you will find in the default script.


```
:: 3. Install bower packages at DEPLOYMENT_SOURCE instead of DEPLOYMENT_TARGET
echo =======  Installing bower: Starting at %TIME% ======= 
IF EXIST "%DEPLOYMENT_SOURCE%\bower.json" (
 pushd "%DEPLOYMENT_SOURCE%"
 call :ExecuteCmd ".\node_modules\.bin\bower.cmd" install
 IF !ERRORLEVEL! NEQ 0 goto error
 popd
 )
echo =======  Installing bower: Finished at %TIME% ======= 
```

Once dev dependancies are installed, run `bower install` through script indie DEPLOYMENT_SOURCE folder.

```
:: 4 Execute Gulp tasks at DEPLOYMENT_SOURCE instead of DEPLOYMENT_TARGET
echo =======  Executing gulp task release: Starting at %TIME% ======= 
IF EXIST "%DEPLOYMENT_SOURCE%\gulpfile.js" (
  pushd "%DEPLOYMENT_SOURCE%"
  echo "Building web site using Gulp" 
  ::call :ExecuteCmd !GULP_CMD! release-uncompress
  call :ExecuteCmd ".\node_modules\.bin\gulp.cmd" build --env prod
  call :ExecuteCmd ".\node_modules\.bin\gulp.cmd" release
  
  IF !ERRORLEVEL! NEQ 0 goto error
  popd
)
echo =======  Executing Gulp task release: Finished at %TIME% ======= 
```

Once bower is sucessfully install, run gulp build script. Here in the above code snipet I use two gulp task to build font-end app into production version. It is completely upto you now you write your gulp task to build you application.

**Remember you are sill building your application inside DEPLOYMENT_SOURCE folder which is D:\home\site\repository**

Now font-end application is completed building for production version inside repository folder. Its the time to copy or sync `dist` folder to wwwroot's `dist` folder. Let's do it.

```
:: 5. Do KuduSync BEFORE INSTALLING PRODUCTION DEPENDANCIES
echo ======= Kudu Syncing: Starting at %TIME% ======= 
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_SOURCE%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.vscode;node_modules;src;typings;.bowerrc;.deployment;.gitignore;bower.json;deploy.cmd;gulpfile.js;tsconfig.json;tsd.json;.hg;.deployment;deploy.cmd;*.xml;*.yml"
  IF !ERRORLEVEL! NEQ 0 goto error
)
echo ======= Kudu Syncing: Finished at %TIME% =======
```

Copying `dist` folder and other nodejs server code from repository folder to `wwwroot` folder. Undertand different meaning of flags used in KuduSync command above [here](https://github.com/projectkudu/KuduSync). -f means source, -t means target folder and -i ignore file (**which is important in above command otherwise it will copy all repository folder which is BAD**)

Let's slow down a little bit and summarise what we have done till this point and what is pending
* We restored devDependancies in repository folder - DONE
* We restored bower dependancies in repository folder  - DONE
* We build font-end app for production verion inside repository folder  - DONE
* We copied dist folder and node server code from repository to wwwroot folder  - DONE
* Restore dependancies which is defined in `dependancies` folder - pending

Let's restore it

```
:: 6. Install npm packages at DEPLOYMENT_TARGET 
echo =======  Installing npm packages: Starting at %TIME% ======= 
IF EXIST "%DEPLOYMENT_TARGET%\package.json" (
  pushd "%DEPLOYMENT_TARGET%"
  call :ExecuteCmd !NPM_CMD! install --production
  IF !ERRORLEVEL! NEQ 0 goto error
  popd
)
echo =======  Installing npm packages: Finished at %TIME% ======= 
```

Now take a deep breath it's done.

Let me know if have any trouble/issue following the steps. I will surely revert back if I can help
