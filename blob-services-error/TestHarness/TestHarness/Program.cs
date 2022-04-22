// See https://aka.ms/new-console-template for more information

using System.Threading.Channels;
using Azure.Core;
using BicepRunner;

while (true)
{
    var runner =
        new AzBicepRunner.AzBicepRunner(
            @"C:\code\github\graemefoster\bicep-tests\blob-services-error",
            AzureLocation.AustraliaEast,
            Guid.Parse("8d2059f3-b805-41fa-ab84-e13d4dfec042"));

    Console.WriteLine($"Deploying template at {DateTimeOffset.Now}.");
    var templateExecution = await runner.ExecuteTemplate(ExecutableTemplate.ResourceGroupScope("storage-test",
        new MainModule()
        {
            Accesstier = "Hot",
            Allowblobpublicaccess = false,
            Allowsharedkeyaccess = false,
            Tags = new { },
            Containername = "",
            Supportshttpstrafficonly = true,
            Filesharename = "",
            Ignoreresourceidentifier = true,
            Kind = "StorageV2",
            Location = "australiaeast",
            Name = "ba4m7dgtjhkbu",
            Skuname = "Standard_LRS",
            Subnetid =
                "/subscriptions/8d2059f3-b805-41fa-ab84-e13d4dfec042/resourceGroups/storage-test/providers/Microsoft.Network/virtualNetworks/ba4m7dgtjhkbu-vnet/subnets/vms",
            Networkacls = new { }
        }));
    var result = templateExecution.Output;
    Console.WriteLine($"Deploy finished at {DateTimeOffset.Now}.");
    await Task.Delay(TimeSpan.FromMinutes(20));
}