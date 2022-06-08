using Newtonsoft.Json;

namespace DeviceReader.Models
{
    public class DeviceReading
    {
        [JsonProperty("id")]
        public string DeviceId { get; set; }
        public decimal DeviceTemperature { get; set; }
        public string DamageLevel { get; set; }
        public string Location { get; set; }
        public int DeviceAgeInDays { get; set; }
    }
}
