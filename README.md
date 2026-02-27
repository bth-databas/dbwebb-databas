# @dbwebb/databas CLI 

A cli to work with the course databas, for students and staff.



## Install

You can install the tool through npm as this.

```bash
npm i @dbwebb/databas --save-dev
```



### Update

You can update to the latest version like this.

```bash
npm update @dbwebb/databas@latest
```



## Execute the `check` command

You can execute the command like this and the result is a helptext on how to use the command.

```bash
npx @dbwebb/databas check <kmom>
```

The following commands are supported.

```bash
npx @dbwebb/databas check labbmiljo
npx @dbwebb/databas check kmom01
npx @dbwebb/databas check kmom02
npx @dbwebb/databas check kmom03
npx @dbwebb/databas check kmom04
npx @dbwebb/databas check kmom05
npx @dbwebb/databas check kmom06
```

<!--
npx @dbwebb/databas check kmom07
npx @dbwebb/databas check kmom08
npx @dbwebb/databas check kmom10
-->

When you run kmom01, it will also check labbmiljo.

When you run kmom02, it will also check kmom01 and labbmiljo (and so on).

You can check only one specific kmom like this.

```bash
npx @dbwebb/databas check kmom02 --only-this
```

You can get a helptext like this.

```bash
npx @dbwebb/databas check --help
```


<!--
### Execute subcommand `check lab`

This command prints out the summary row from a lab and visualises the points on each lab. This is used to show a summary of the points of several labs.

You can use it like this to show the results from one lab.

```
# Show the result from one lab
npx @dbwebb/databas check lab lab_01
```

You can use it like this to show the results from several labs.

```
# Show the result from one lab
npx @dbwebb/databas check lab lab_01 lab_02
```
-->



<!--
## To be done

These will be supported but are yet not implemented.

```bash
npx @dbwebb/databas check kmom10
```
-->



<!--
## Developer

Use `npm link` to make a local link to the scripts. Then run like this.

```bash
check-files
help
```
-->