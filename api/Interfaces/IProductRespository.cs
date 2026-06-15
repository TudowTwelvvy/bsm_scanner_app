using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Models;
using api.DTOs.Product;

namespace api.Interfaces
{
    public interface IProductRespository
    {
        Task<List<Product>> GetAllProductsAsync(string userId);
        Task<Product?> GetProductByIdAsync(int id, string userId);
        //accept DTO + userId instead of raw Product entity
        // The entity's UserId is set BY THE REPOSITORY, not the client
        Task<Product> CreateProductAsync(CreateProductReqDto dto, string userId);
        Task<Product?> UpdateProductAsync(int id, UpdateProductReqDto updateProductReqDto, string userId);
        Task<bool> DeleteProductAsync(int id, string userId);
        //Count is a separate method for performance.
        // SELECT COUNT(*) is much faster than fetching all rows.
        Task<int> GetProductCountAsync(string userId);
    
    }
}