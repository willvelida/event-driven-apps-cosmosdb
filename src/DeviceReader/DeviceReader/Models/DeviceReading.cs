﻿using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
