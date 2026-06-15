using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;
using api.DTOs.Product;

namespace api.Models
{
    public class Product
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }
       
        public string Barcode { get; set; } = string.Empty;
        
        public string? ProductName { get; set; }

        public string? Notes { get; set; }
        
        public string BarCodeType { get; set; } = "UNKNOWN";

        public DateTime ScannedAt { get; set; } = DateTime.UtcNow;
        
        // Foreign key to User
        // This indicates which user scanned this product
        //public int? UserId { get; set; }
        public string UserId { get; set; } = string.Empty;



        // Navigation property
        // This allows us to access the User associated with this Product
        //[ForeignKey(nameof(UserId))]// This attribute specifies that the UserId property is a foreign key that references the User entity
        [ForeignKey(nameof(UserId))]
        public AppUser User { get; set; } = null!;

        public ProductDto ToProductDto()
        {
            return new ProductDto
            {
                Id = this.Id,
                Barcode = this.Barcode,
                ProductName = this.ProductName,
                Notes = this.Notes,
                BarCodeType = this.BarCodeType,
                ScannedAt = this.ScannedAt
            };
        }
    }
}