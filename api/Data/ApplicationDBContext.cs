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

    builder.Entity<Product>(entity =>
            {
                entity.HasIndex(p => p.Barcode);
                entity.HasIndex(p => p.ScannedAt);
                entity.HasIndex(p => p.UserId);

                // Cascade delete: when user is deleted, their products are deleted
                entity.HasOne(p => p.User)
                      .WithMany(u => u.Products)
                      .HasForeignKey(p => p.UserId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

    builder.Entity<IdentityRole>().HasData(
        new IdentityRole
        {
            Id = "1",
            Name = "User",
            NormalizedName = "USER",
            ConcurrencyStamp = "c1"
        },
        new IdentityRole
        {
            Id = "2",
            Name = "Admin",
            NormalizedName = "ADMIN",
            ConcurrencyStamp = "c2"
        }
    );
}
        
    
    }
}