# Developer info

This is how to work as a developer within a project like this.



## Get going

1. Create a public git repo for the project.
1. Publish it as a npm package using `npm publish`, do a `npm login` first.



## Run scripts locally

Execute local scripts within the repo like this.

```bash
bin/dbw-databas.bash version
bin/dbw-databas.bash help
```



## Use npm link for development

When working, use `npm link` to avoid install and copy.

In this repo.

```bash
npm link
```

In the repo you want to use these files.

```bash
npm link @dbwebb/databas
```

Now you can execute the command as usual.

```bash
npx @dbwebb/databas -h
npx @dbwebb/databas version
```
