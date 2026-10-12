# WORK IN PROGRESS

## SQL Server Best Practices and Settings

### Config

1. Set report output on each step in SQL Agent jobs for long running jobs, ie full/diff backups. The output for these jobs ends up being too long to be fully viewable in SQL Agent and the error cannot be viewed. Example of report path with tags:

   ````M:\Management\Reports\$(ESCAPE_SQUOTE(JOBNAME))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt````

2. Trace flags:
   1. 3226 - Disable logging of successful backups in server Log.
   2. 9567 - Enable autoseeding compression.

### Scripts

1. Maintenance Solution: https://ola.hallengren.com/
2. First Responder Kit: https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit
