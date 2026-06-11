using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Data;
using api.DTOs.Product;
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
        public ProductController(ApplicationDBContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetProducts()
        {
             var products = await _context.Products.Select(p => ProductMappers.ToProductDto(p)).ToListAsync();
             //var products = await _context.Products.Select(p => ProductMappers.ToProductDto(p)).ToListAsync();
            return Ok(products);
        }


        [HttpGet("{id}")]
        public async Task<IActionResult> GetProduct(int id)
        {
            var product = await _context.Products.FirstOrDefaultAsync(p => p.Id == id);
            if (product == null)
            {
                return NotFound();
            }
            return Ok(ProductMappers.ToProductDto(product));
        }

        [HttpPost]
        public IActionResult CreateProduct([FromBody] CreateProductReqDto createProductReqDto)
        {
            var product = ProductMappers.ToProduct(createProductReqDto);
            _context.Products.Add(product);
            _context.SaveChanges();
            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, ProductMappers.ToProductDto(product));
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] UpdateProductReqDto updateProductReqDto)
        {
            var product = await _context.Products.FirstOrDefaultAsync(p => p.Id == id);
            if (product == null)
            {
                return NotFound();
            }
            /*product.ProductName = updateProductReqDto.ProductName ?? product.ProductName;
            product.Notes = updateProductReqDto.Notes ?? product.Notes;*/
            ProductMappers.UpdateProductFromDto(product, updateProductReqDto);
            _context.SaveChanges();
            return Ok(ProductMappers.ToProductDto(product));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FirstOrDefaultAsync(p => p.Id == id);
            if (product == null)
            {
                return NotFound();
            }
            _context.Products.Remove(product);
            _context.SaveChanges();
            return NoContent();
        }

    }
}