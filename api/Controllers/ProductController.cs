using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Data;
using api.DTOs.Product;
using api.Interfaces;
using api.Mappers;
using api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;


namespace api.Controllers
{
    [Route("api/product")]
    [ApiController]
    public class ProductController: ControllerBase 
    {
        private readonly ApplicationDBContext _context;
        private readonly IProductRespository _productRespository;
        public ProductController(ApplicationDBContext context, IProductRespository productRespository)
        {
            _context = context;
            _productRespository = productRespository;
        }

        [HttpGet]
        public async Task<IActionResult> GetProducts()
        {
            var products = await _productRespository.GetAllProductsAsync();
             //var products = await _context.Products.Select(p => ProductMappers.ToProductDto(p)).ToListAsync();
             //var products = await _context.Products.Select(p => ProductMappers.ToProductDto(p)).ToListAsync();
            return Ok(products);
        }


        [HttpGet("{id}")]
        public async Task<IActionResult> GetProduct(int id)
        {
            var product = await _productRespository.GetProductByIdAsync(id);
            if (product == null)
            {
                return NotFound();
            }
            return Ok(ProductMappers.ToProductDto(product));
        }

        [HttpPost]
        public async Task<IActionResult> CreateProduct([FromBody] CreateProductReqDto createProductReqDto)
        {
            var product = ProductMappers.ToProduct(createProductReqDto);
            await _productRespository.CreateProductAsync(product);
            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, ProductMappers.ToProductDto(product));
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] UpdateProductReqDto updateProductReqDto)
        {
            var product = await _productRespository.GetProductByIdAsync(id);
            if (product == null)
            {
                return NotFound();
            }
            /*product.ProductName = updateProductReqDto.ProductName ?? product.ProductName;
            product.Notes = updateProductReqDto.Notes ?? product.Notes;*/
            ProductMappers.UpdateProductFromDto(product, updateProductReqDto);
            await _productRespository.UpdateProductAsync(id, updateProductReqDto);
            return Ok(ProductMappers.ToProductDto(product));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _productRespository.GetProductByIdAsync(id);
            if (product == null)
            {
                return NotFound();
            }
            await _productRespository.DeleteProductAsync(id);
            return NoContent();
        }

    }
}