using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.DTOs.Product;
using api.Models;

namespace api.Mappers
{
    public class ProductMappers
    {
        public static ProductDto ToProductDto(Product product)
        {
            return new ProductDto
            {
                Id = product.Id,
                Barcode = product.Barcode,
                ProductName = product.ProductName,
                Notes = product.Notes,
                BarCodeType = product.BarCodeType,
                ScannedAt = product.ScannedAt,
    
            };
        }
    }
}