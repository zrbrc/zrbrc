# Powershell Basics

## Powershell Features/Syntax

1. All commands are generally in the format of ``Verb-Noun``, example, ``Get-Item``.

2. There can be and are exceptions, but Microsoft has approved Verbs to be used in commands. That dosent mean a developer cannot use them, but they are suggested to use them. Most if not all MS modules will be using approved verbs, 3rd party modules are usually correct as well.

3. Output from powershell commands are objects. This is different than output on the dos/cmd command-line, that is plain text. Output being objects is very powerful and allows working with output much easier. You can access/address individual properties on items and iterate thru them.

4. Pipeline

5. Aliases

6. Built-in help.

   Get-Help Get-Item

7. Tab-completion, start typing a command and hit tab to cycle thru avialble commands that match what has been typed so far. Hit up arrow to go to previously typed commands.

## Install Modules

1. Open an Administrator (elevated) Powershell window  

2. Remote System Administration Tools (RSAT) Active Directory Module, open Start Menu and search for and click on **Optional Features**. Find RSAT Active Directory and install it.     

3. ImportExcel Module
   Install-Module ImportExcel

4. Verify both are installed

   Get-Module -ListAvailable ImportExcel, ActiveDirectory

## Powershell Basics
5. Get-Item  

6. Get-ADUser, AD cmdlets are special, they do not return all properties by default, this is save cycles on AD.

7. Out-GridView

8. ExportExcel.