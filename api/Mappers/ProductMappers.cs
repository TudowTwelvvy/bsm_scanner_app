using System;
using System.Collections.Generic;
using System.Diagnostics.Metrics;
using System.Linq;
using System.Threading.Tasks;
using api.DTOs.Product;
using api.Models;

namespace api.Mappers
{
    public class ProductMappers
    {
        /*public static ProductDto ToProductDto(Product product)
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
        }*/

        /*public static Product ToProduct(CreateProductReqDto createProductReqDto)
        {
            return new Product
            {
                Barcode = createProductReqDto.Barcode,
                ProductName = createProductReqDto.ProductName,
                Notes = createProductReqDto.Notes,
                BarCodeType = createProductReqDto.BarCodeType,
                //ScannedAt = createProductReqDto.ScannedAt,
                //UserId = createProductReqDto.UserId
            };
        }*/

        public static void UpdateProductFromDto( Product product, UpdateProductReqDto updateProductReqDto)
        {
            if (updateProductReqDto.ProductName != null)
            {
                product.ProductName = updateProductReqDto.ProductName;
            }
            if (updateProductReqDto.Notes != null)
            {
                product.Notes = updateProductReqDto.Notes;
            }
        }

    }
}