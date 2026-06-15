using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using api.Data;
using api.DTOs.Product;
using api.Interfaces;
using api.Mappers;
using api.Models;
using api.Respository;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;


namespace api.Controllers
{
    [Route("api/product")]
    [ApiController]
    [Authorize]
    public class ProductController: ControllerBase 
    {
        private readonly ApplicationDBContext _context;
        private readonly IProductRespository _productRespository;
        private readonly UserManager<AppUser> _userManager;
        public ProductController(ApplicationDBContext context, IProductRespository productRespository, UserManager<AppUser> userManager)
        {
            _context = context;
            _productRespository = productRespository;
            _userManager = userManager;
        }

         private int GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            //JWT claims are ALWAYS strings. Our database uses int for UserId.
            return int.Parse(userIdClaim!);
        }

        //this is Belt-and-suspenders security... The token might be valid but the user could have been deleted from the database since the token was issued.
        // This check prevents "orphan token" attacks.
        private async Task<AppUser?> GetCurrentUserAsync()
        {
            var userId = GetCurrentUserId();
            return await _userManager.FindByIdAsync(userId.ToString());
        }

        [HttpGet]
        public async Task<IActionResult> GetProducts()
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = GetCurrentUserId();

            var products = await _productRespository.GetAllProductsAsync(userId);
             //var products = await _context.Products.Select(p => ProductMappers.ToProductDto(p)).ToListAsync();
             //var products = await _context.Products.Select(p => ProductMappers.ToProductDto(p)).ToListAsync();
             
             //map to DTOs before returning. Never expose entities directly.
            // Entities might contain navigation properties that cause circular references in JSON serialization (infinite loops).
            var productDtos = products.Select(p => p.ToProductDto()).ToList();
            return Ok(productDtos);
        }


        [HttpGet("{id}")]
        public async Task<IActionResult> GetProduct(int id)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = GetCurrentUserId();

            var product = await _productRespository.GetProductByIdAsync(id, userId);
            if (product == null)
            {
                return NotFound();
            }
            return Ok(ProductMappers.ToProductDto(product));
        }

        [HttpPost()]
        public async Task<IActionResult> CreateProduct([FromBody] CreateProductReqDto createProductReqDto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = GetCurrentUserId();

            var product = ProductMappers.ToProduct(createProductReqDto);
            await _productRespository.CreateProductAsync(createProductReqDto, userId);
            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, ProductMappers.ToProductDto(product));
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] UpdateProductReqDto updateProductReqDto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = GetCurrentUserId();

            var product = await _productRespository.UpdateProductAsync(id, updateProductReqDto, userId );
            if (product == null)
            {
                return NotFound();
            }
            /*product.ProductName = updateProductReqDto.ProductName ?? product.ProductName;
            product.Notes = updateProductReqDto.Notes ?? product.Notes;*/
           
            return Ok(ProductMappers.ToProductDto(product));
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var userId = GetCurrentUserId();
            
            var product = await _productRespository.DeleteProductAsync(id, userId);
            if (!product)
            {
                return NotFound();
            }
            
            return NoContent();
        }

        [HttpGet("count")]
        public async Task<ActionResult<int>> GetCount()
        {
            var userId = GetCurrentUserId();
            var count = await _productRespository.GetProductCountAsync(userId);
            return Ok(count);
        }


    }
}