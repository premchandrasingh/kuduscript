# Custom Continuous Deployment Script (Kudu) for Node-Angular and Asp.net Application

#### Folders
* `node-angular` - Node js server which have font-end application in Angular which have bower to resolve client dependancies and gulp to automate build process
* `asp.net` - Asp.net application having multiple projects and want to deploy a main project


# Quick Notes on Command Line

Reference :-
- [https://ss64.com](https://ss64.com)
- [https://ss64.com/nt](https://ss64.com/nt)
- [https://ss64.com/nt/syntax-args.html](https://ss64.com/nt/syntax-args.html)
- [https://ss64.com/nt/if.html](https://ss64.com/nt/if.html) etc

### [ECHO](https://ss64.com/nt/echo.html)
Display messages on screen, turn command-echoing on or off.

```Syntax
      ECHO [ON | OFF] 
      ECHO [message]
      
    Key
          ON      : Display each line of the batch on screen (default)
          OFF     : Only display the command output on screen
          message : a string of characters to display
```

### [IF](https://ss64.com/nt/if.html)
```
File syntax
   IF EXIST filename command 
   IF NOT EXIST filename (command) ELSE (command)

String syntax
   IF [/I] [NOT] item1==item2 command      <<==== Do a case Insensitive string comparison.
   IF [/I] item1 compare-op item2 command

Error Check Syntax
   IF [NOT] DEFINED variable command
   IF [NOT] ERRORLEVEL number command

Keys
   compare-op can be one of
               EQU : Equal
               NEQ : Not equal

               LSS : Less than <
               LEQ : Less than or Equal <=

               GTR : Greater than >
               GEQ : Greater than or equal >=
               
    This 3 digit syntax is necessary because the > and < symbols are recognised as redirection operators
```
#### Caution in IF: 
```
IF "value1" EQU "value2"(command) is invalid syntax 
IF "value1" EQU "value2" (command) is correct syntax. Note the space after value2
```

### [PUSHD](https://ss64.com/nt/pushd.html) & [POPD](https://ss64.com/nt/popd.html)

Change the current directory/folder and store the previous folder/path for use by the POPD command.

```
Examples

C:\demo> pushd \work 
C:\work> popd
C:\demo> pushd "F:\monthly reports"
F:\monthly reports> popd
C:\demo>
```
### [setlocal](https://ss64.com/nt/setlocal.html) & [endlocal](https://ss64.com/nt/endlocal.html)

`setlocal` Set options to control the visibility of environment variables in a batch file.

`endlocal` End localisation of environment changes in a batch file. Pass variables from one batch file to another.

### [CALL](https://ss64.com/nt/call.html)
Call one batch program from another, or call a subroutine.
```
Syntax
     CALL [path to executable] [parameters]
     CALL :label [parameters]
Keys
    parameters   Any command-line arguments.
    :label       Jump to a label in the current batch script.
```
##### *CALL a subroutine (:label)*
The CALL command will pass control to the statement after the label specified along with any specified parameters.
To exit the subroutine specify `GOTO:eof` this will transfer control to the end of the current subroutine.

A label is defined by a single colon followed by a name. This is the basis of a batch file function.
```
For Example
          CALL :sub_display 123
          CALL :sub_display 456
          ECHO All Done
          GOTO :eof

          :sub_display
          ECHO The result is %1        <<==== Accessing parameter passed to sub-rutine sub_display
          EXIT /B
```
At the end of the subroutine an `EXIT /B` will return to the position where you used `CALL` 
(`GOTO :eof` can also be used for this)

##### *Accessing Parameter in subrutine*
 You can get the value of any argument using a `%` followed by it's numerical position on the command line. The first item passed is always `%1` the second item is always `%2` and so on

`%*` in a batch script refers to `all` the arguments (e.g. %1 %2 %3 %4 %5 ...%255) 

### [EXIT](https://ss64.com/nt/exit.html)
Quit the current batch script, quit the current subroutine or quit the command processor (CMD.EXE) optionally setting an errorlevel code.

```
Syntax
      EXIT [/B] [exitCode]

Key
    /B        When used in a batch script, this option will exit 
              only the script (or subroutine) but not CMD.EXE

   exitCode   Sets the %ERRORLEVEL% to a numeric number.
              If quitting CMD.EXE, set the process exit code no.
```
`EXIT /b` has the option to set a specific errorlevel, `0` for `sucess`, `1 or greater` for an `error`. 

