using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace api.Models
{
    public class Product
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
        
        // Foreign key to User
        // This indicates which user scanned this product
        [Required]
        public int UserId { get; set; }
        // Navigation property
        // This allows us to access the User associated with this Product
        public User? User { get; set; }
    }
}