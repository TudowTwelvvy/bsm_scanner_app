using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace api.DTOs.Product
{
    public class ProductDto
    {
         public int Id { get; set; }
        [Required]
        [MaxLength(500)]
        public string Barcode { get; set; } = string.Empty;
        [MaxLength(255)]
        public string? ProductName { get; set; }
        [MaxLength(1000)]
        public string? Notes { get; set; }
        [Required]
        [MaxLength(100)]
        public string BarCodeType { get; set; } = "UNKNOWN";

        public DateTime ScannedAt { get; set; } = DateTime.UtcNow;
        
        //user was here below
        
    }
}