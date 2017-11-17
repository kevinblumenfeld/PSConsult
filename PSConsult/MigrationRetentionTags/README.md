
1.	In Exchange Online run: Enable-OrganizationCustomization  
2.	Acquire newer export/import retention scripts from 2016 and place them in c:\scripts\  
    a.	EXPORT (EXCHANGE ONPREM):  
          i.	https://github.com/kevinblumenfeld/PSConsult/blob/master/PSConsult/Export-RetentionTags.ps1   
          ii.	.\Export-RetentionTags.ps1 "c:\scripts\ExportedRetentionTags.xml"  
    b.	IMPORT(365):   
          i.	https://github.com/kevinblumenfeld/PSConsult/blob/master/PSConsult/Import-RetentionTags.ps1   
          ii.	.\Import-RetentionTags.ps1 "c:\scripts\ExportedRetentionTags.xml"   


