workflow Test-Workflow  
{  
    Parallel  
    {  
Copy-Item -Path C:\support\Seed100KB.txt  -Destination C:\Users\--r\Desktop\deneme1
Copy-Item -Path C:\support\Seed100KB.txt  -Destination C:\Users\--r\Desktop\deneme2
    }  
}

Test-Workflow