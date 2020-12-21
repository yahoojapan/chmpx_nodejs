---
layout: contents
language: ja
title: Build
short_desc: CHMPX Node.js - CHMPX addon library for Node.js
lang_opp_file: build.html
lang_opp_word: To English
prev_url: usageja.html
prev_string: Usage
top_url: indexja.html
top_string: TOP
next_url: developerja.html
next_string: Developer
---

# ビルド方法
CHMPX Node.js アドオンライブラリをビルドする方法を説明します。

## 1. 事前環境
- 最近のDebianベースLinuxの利用者は、以下の手順に従ってください。
```
$ sudo aptitude update
$ sudo aptitude git gcc g++ make gdb dh-make fakeroot dpkg-dev
$ sudo aptitude install nodejs npm
```
- Fedoraの利用者は、以下の手順に従ってください。
```
$ sudo dnf install git autoconf automake gcc libstdc++-devel gcc-c++ make libtool
$ sudo dnf install nodejs npm
```
- その他最近のRPMベースのLinuxの場合は、以下の手順に従ってください。
```
$ sudo yum install git autoconf automake gcc libstdc++-devel gcc-c++ make libtool
$ sudo yum install nodejs npm
```
インストールするNode.jsの環境は個々の環境で整えてください。

## 2. CHMPXライブラリ
[CHMPX](https://chmpx.antpick.ax/indexja.html)ライブラリを事前にパッケージ（開発者パッケージ）インストール、もしくはご自身でビルド・インストールしてください。  
[CHMPX](https://chmpx.antpick.ax/indexja.html)ライブラリのインストール方法は[こちら](https://chmpx.antpick.ax/usageja.html)、ビルド方法は、[こちら](https://chmpx.antpick.ax/buildja.html)を参照してください。

## 3. clone
```
$ git clone git@github.com:yahoojapan/chmpx_nodejs.gif
$ cd chmpx_nodejs
```

## 4. ビルド・テスト
[npm](https://www.npmjs.com/get-npm)コマンドを使ってビルドとテストを実行します。  
```
$ sudo npm cache clean
$ npm update
$ npm run build
$ npm run test
```
ビルド、テストが成功した場合には、以下のパスにchmpx.nodeファイルができています。（トップディレクトリ直下にbuildというシンボリックリンクもできています。）
```
$ ls -la build
lrwxrwxrwx 1 guest users     43 Nov 30 14:00 build -> /home/guest/chmpx_nodejs/src/build

$ ls -l src/build/Release/*.node
total 252
-rwxr-xr-x 1 guest users 240637 Nov 30 14:00 chmpx.node
```
