using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity;

namespace api.Models
{
    public class AppUser : IdentityUser
    {
        // Custom properties beyond what Identity provides
        public string? DisplayName { get; set; }
        public DateTime CreatedAt { get; set; }

        //Navigation property: one user has many products 
        public List<Product> Products { get; set; } = new();
        
    }
}