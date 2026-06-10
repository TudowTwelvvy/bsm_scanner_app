using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace api.DTOs.Product
{
    public class ProductDto
    {
         public int Id { get; set; }
        public string Barcode { get; set; } = string.Empty;

        public string? ProductName { get; set; }
        
        public string? Notes { get; set; }
        
        public string BarCodeType { get; set; } = "UNKNOWN";

        public DateTime ScannedAt { get; set; } = DateTime.UtcNow;
        
        //user was here below
    }
}