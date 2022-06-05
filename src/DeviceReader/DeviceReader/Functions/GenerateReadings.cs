using Bogus;
using DeviceReader.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace DeviceReader.Functions
{
    public class GenerateReadings
    {
        private readonly ILogger<GenerateReadings> _logger;

        public GenerateReadings(ILogger<GenerateReadings> logger)
        {
            _logger = logger;
        }

        [FunctionName(nameof(GenerateReadings))]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "GenerateReadings/{numberOfEvents}")] HttpRequest req,
            [EventHub("readings", Connection = "EventHubConnection")] IAsyncCollector<DeviceReading> outputEvents,
            int numberOfEvents)
        {
            try
            {
                var deviceIterations = new Faker<DeviceReading>()
                .RuleFor(i => i.DeviceId, (fake) => Guid.NewGuid().ToString())
                .RuleFor(i => i.DeviceTemperature, (fake) => Math.Round(fake.Random.Decimal(0.00m, 30.00m), 2))
                .RuleFor(i => i.DamageLevel, (fake) => fake.PickRandom(new List<string> { "Low", "Medium", "High" }))
                .RuleFor(i => i.Location, (fake) => fake.PickRandom(new List<string> { "Auckland", "Redmond", "London", "Dubai", "Paris"}))
                .RuleFor(i => i.DeviceAgeInDays, (fake) => fake.Random.Number(1, 60))
                .GenerateLazy(numberOfEvents);

                foreach (var reading in deviceIterations)
                {
                    await outputEvents.AddAsync(reading);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Exception thrown in {nameof(GenerateReadings)}: {ex.Message}");
                throw;
            }

            return new OkResult();
        }
    }
}
