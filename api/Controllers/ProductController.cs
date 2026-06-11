using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Data;
using api.DTOs.Product;
using api.Mappers;
using api.Models;
using Microsoft.AspNetCore.Mvc;

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
        public IActionResult GetProducts()
        {
            var products = _context.Products.Select(p => ProductMappers.ToProductDto(p)).ToList();
            return Ok(products);
        }


        [HttpGet("{id}")]
        public IActionResult GetProduct(int id)
        {
            var product = _context.Products.FirstOrDefault(p => p.Id == id);
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
        public IActionResult UpdateProduct(int id, [FromBody] UpdateProductReqDto updateProductReqDto)
        {
            var product = _context.Products.FirstOrDefault(p => p.Id == id);
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
        public IActionResult DeleteProduct(int id)
        {
            var product = _context.Products.FirstOrDefault(p => p.Id == id);
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