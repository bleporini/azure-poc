```bash 
docker run --rm -ti -v $(pwd)/.azure:/root/.azure -v $(pwd)/.ssh:/root/.ssh -v $(pwd):/source --workdir /source  -e GROUP_NAME=<the resource group name you have to define> mcr.microsoft.com/azure-cli ./setup.sh
```

