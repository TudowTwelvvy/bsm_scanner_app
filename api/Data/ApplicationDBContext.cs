using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace api.Data
{
    public class ApplicationDBContext : IdentityDbContext<AppUser>
    {
        public ApplicationDBContext(DbContextOptions<ApplicationDBContext> options) : base(options)
        {
        }

        //public DbSet<User> Users { get; set; }
        public DbSet<Product> Products { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
{
    base.OnModelCreating(builder);

    builder.Entity<IdentityRole>().HasData(
        new IdentityRole
        {
            Id = "11111111-1111-1111-1111-111111111111",
            Name = "User",
            NormalizedName = "USER",
            ConcurrencyStamp = "c1"
        },
        new IdentityRole
        {
            Id = "22222222-2222-2222-2222-222222222222",
            Name = "Admin",
            NormalizedName = "ADMIN",
            ConcurrencyStamp = "c2"
        }
    );
}
        
    
    }
}