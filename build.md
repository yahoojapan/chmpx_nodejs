---
layout: contents
language: en-us
title: Build
short_desc: CHMPX Node.js - CHMPX addon library for Node.js
lang_opp_file: buildja.html
lang_opp_word: To Japanese
prev_url: usage.html
prev_string: Usage
top_url: index.html
top_string: TOP
next_url: developer.html
next_string: Developer
---

# Building
The build method for CHMPX Node.js addon library is explained below.

## 1. Install prerequisites before compiling
- For recent Debian-based Linux distributions users, follow the steps below:
```
$ sudo aptitude update
$ sudo aptitude git gcc g++ make gdb dh-make fakeroot dpkg-dev
$ sudo aptitude install nodejs npm
```
- For users who use supported Fedora other than latest version, follow the steps below:
```
$ sudo dnf install git autoconf automake gcc libstdc++-devel gcc-c++ make libtool
$ sudo dnf install nodejs npm
```
- For other recent RPM-based Linux distributions users, follow the steps below:
```
$ sudo yum install git autoconf automake gcc libstdc++-devel gcc-c++ make libtool
$ sudo yum install nodejs npm
```

## 2. K2HASH library
In advance, you need to install the developer package of [CHMPX](https://chmpx.antpick.ax/) library(See [here](https://chmpx.antpick.ax/usage.html) for installation).  
Without installing this package, you can also build the [CHMPX](https://chmpx.antpick.ax/) library(See [here](https://chmpx.antpick.ax/build.html) for the build).

## 3. Clone source codes from Github
```
$ git clone git@github.com:yahoojapan/chmpx_nodejs.gif
$ cd chmpx_nodejs
```

## 4. Building and Testing
Run the build and test using the [npm](https://www.npmjs.com/get-npm) command.
```
$ sudo npm cache clean
$ npm update
$ npm run build
$ npm run test
```
If the building and testing succeed, you can find three **chmpx.node** files in the following path. (And a symbolic link **build** under the top directory.)
```
$ ls -la build
lrwxrwxrwx 1 guest users     43 Nov 30 14:00 build -> /home/guest/chmpx_nodejs/src/build

$ ls -l src/build/Release/*.node
total 252
-rwxr-xr-x 1 guest users 240637 Nov 30 14:00 chmpx.node
```
