using DeviceReader.Models;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace DeviceReader.Functions
{
    public class MaterializeReadings
    {
        private readonly ILogger<MaterializeReadings> _logger;
        private readonly IConfiguration _configuration;
        private readonly CosmosClient _cosmosClient;
        private readonly Container _container;

        public MaterializeReadings(ILogger<MaterializeReadings> logger, IConfiguration configuration, CosmosClient cosmosClient)
        {
            _logger = logger;
            _configuration = configuration;
            _cosmosClient = cosmosClient;
            _container = _cosmosClient.GetContainer(_configuration["DatabaseName"], _configuration["ReadContainer"]);
        }

        [FunctionName(nameof(MaterializeReadings))]
        public async Task Run([CosmosDBTrigger(
            "ReadingsDb",
            "Readings",
            Connection = "CosmosDbConnection",
            LeaseContainerName = "leases",
            LeaseContainerPrefix = "Locations"
            )]IReadOnlyList<DeviceReading> input)
        {
            try
            {
                if (input != null && input.Count > 0)
                {
                    foreach (var doc in input)
                    {
                        _logger.LogInformation($"Materializing reading from Device Id: {doc.DeviceId} in {doc.Location}");
                        await _container.CreateItemAsync(doc, new PartitionKey(doc.Location));
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Exception thrown in {nameof(MaterializeReadings)}: {ex.Message}");
                throw;
            }
        }
    }
}
