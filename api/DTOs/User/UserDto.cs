using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;
using api.DTOs.Product;
using api.Models;

namespace api.DTOs.User
{
    public class UserDto
    {
        public int Id { get; set; }
        [Required] // Cannot be null
        [MaxLength(255)] // VARCHAR(255)
        [EmailAddress] // Validates email format
        public string Email { get; set; } = string.Empty;
        public string? DisplayName { get; set; }
        public DateTime CreatedAt { get; set; }

        public List<ProductDto> Products { get; set; } = new();
   
    }
}