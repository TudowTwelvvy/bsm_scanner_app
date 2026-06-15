using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Data;
using api.DTOs.Product;
using api.Interfaces;
using api.Mappers;
using api.Models;
using Microsoft.EntityFrameworkCore;

namespace api.Respository
{
    public class ProductRespository : IProductRespository
    {
        private readonly ApplicationDBContext _context;

        public ProductRespository(ApplicationDBContext context)
        {
            _context = context;
        }

        public async Task<List<Product>> GetAllProductsAsync(int userId)
        {
            return await _context.Products.AsNoTracking().Where(p => p.UserId == userId).OrderByDescending(p => p.ScannedAt).ToListAsync();
        }

        public async Task<Product?> GetProductByIdAsync(int id, int userId)
        {
            return await _context.Products.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);
        }

        public async Task<Product> CreateProductAsync(CreateProductReqDto createProductReqDto,int userId)
        {
            var product = new Product
            {
                Barcode = createProductReqDto.Barcode,
                ProductName = createProductReqDto.ProductName,
                Notes = createProductReqDto.Notes,
                BarCodeType = createProductReqDto.BarCodeType,
                UserId = userId, //FROM JWT, NOT CLIENT. CANNOT BE FAKED.
                ScannedAt = DateTime.UtcNow
            };
            await _context.Products.AddAsync(product);
            await _context.SaveChangesAsync();
            return product;
        }

        public async Task<Product?> UpdateProductAsync(int id, UpdateProductReqDto updateProductReqDto, int userId)
         {
            var product = await _context.Products.FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);
            if (product == null)
            {
                return null;
            }

            ProductMappers.UpdateProductFromDto(product, updateProductReqDto);
            await _context.SaveChangesAsync();
            return product;
         }

        public async Task<bool> DeleteProductAsync(int id, int userId)
        {
            var product = await _context.Products.FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);
            if (product == null)
            {
                return false;
            }

            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
            return true;
        }

        //GET PRODUCT COUNT
        public async Task<int> GetProductCountAsync(int userId)
        {
            // WHY: CountAsync generates: SELECT COUNT(*) FROM Products WHERE UserId = @userId
            // This is O(1) — SQL Server maintains counts internally.
            // Fetching all rows and counting in C# would be O(n) and waste memory.
            return await _context.Products
                .CountAsync(p => p.UserId == userId);
        }


    }
}