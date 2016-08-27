A normal `pulp browserify` works perfectly fine:

```
pulp browserify --to dist/out.js 
```

Using browserify with -O  like this:

```
pulp browserify -O --to dist/out.js
```

You'll be greeted with the following error in console:

```
ReferenceError: dataKeys is not defined
```

If we grep the optimized out.js file for dataKeys we'll see.

Now I'll generate both version:

```
$ pulp browserify --to dist/out.js
$ pulp browserify -O --to dist/out_optimized.js
```

Looking at some differences between the two files..


```
$ wc -l dist/*
  7666 dist/out.js
  1996 dist/out_optimized.js
$ grep dataKeys dist/*
dist/out.js:var dataKeys = ["props", "on", "tween", "keyboard"];
dist/out.js:    dataKeys.forEach(function(x) {
dist/out.js:    dataKeys.forEach(function(dataKey){
dist/out_optimized.js:      dataKeys.forEach(function(x) {
dist/out_optimized.js:      dataKeys.forEach(function(dataKey){

```

We see that the var dataKeys declaration is missing from out_optimized.js.
