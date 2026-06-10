using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace api.Models
{
    public class User
    {
        public int Id { get; set; }
        
        [Required] // Cannot be null
        [MaxLength(255)] // VARCHAR(255)
        [EmailAddress] // Validates email format
        public string Email { get; set; } = string.Empty;
        [Required]
        public string PasswordHash { get; set; } = string.Empty;        public string? DisplayName { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation property
        // This allows us to access the products associated with this user
        public List<Product> Products { get; set; } = new List<Product>();
    }
}