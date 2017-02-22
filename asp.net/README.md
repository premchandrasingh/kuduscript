# Custom Continuous Deployment Script(Kudu) for Asp.net app on Azure


## Custom Deployment Script for Asp.net Project
To download or get default kudu script into your local repository you need to install Azure CLI

```npm install azure-cli -g```

To download default kudu build script for node js project run following command

```azure site deploymentscript --aspWAP project_folder\project.name.csproj -s solution_name.sln``` 

It will create two files in you directory `.deployment` & `deploy.cmd`. **Don't be afraid of scripts in deploy.cmd**. Just focus this will be **going to ease my life** a lot.

Do a little modification (not required at all) to have a better logging.

Watch following video of Scott Hanselman with David Ebbo about kudu
* [Custom Web Site Deployment Scripts with Kudu](https://www.youtube.com/watch?v=FI1PfFVquKo)


Happy deployment