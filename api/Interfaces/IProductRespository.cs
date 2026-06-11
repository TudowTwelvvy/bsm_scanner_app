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
        Task<List<Product>> GetAllProductsAsync();
        Task<Product?> GetProductByIdAsync(int id);
        Task<Product> CreateProductAsync(Product product);
        Task<Product?> UpdateProductAsync(int id, UpdateProductReqDto updateProductReqDto);
        Task<bool> DeleteProductAsync(int id);
       
    }
}