using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Data;
using api.DTOs.Auth;
using api.Interfaces;
using api.Mappers;
using api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Identity.Client;

namespace api.Controllers
{
    [Route("api/auth")]
    [ApiController]
    public class AuthController: ControllerBase
    {
        private readonly UserManager<AppUser> _userManager;

        public AuthController(UserManager<AppUser> userManager)
        {
            _userManager = userManager;
        }

         // POST api/auth/register
         [HttpPost("register")]
         public async Task<ActionResult<AuthResDto>> Register([FromBody] RegisterReqDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                //create user with Identity...it handles password hashing, normalization, security stamp
               var appUser = new AppUser{
                UserName = request.Email,
                Email = request.Email,
                DisplayName = request.DisplayName,
                CreatedAt = DateTime.UtcNow,
                EmailConfirmed = true //skip confirmation for now
               };

               var createUser = await _userManager.CreateAsync(appUser, request.Password);

                if (createUser.Succeeded)
                {
                    var roleResult = await _userManager.AddToRoleAsync(appUser, "User");
                    if (roleResult.Succeeded)
                    {
                        return Ok("User Created");
                    }
                    else
                    {
                        return StatusCode(500, roleResult.Errors);
                    }
                }
                else
                {
                    return StatusCode(500, createUser.Errors);
                }

            }
            catch(Exception e)
            {
                return StatusCode(500, e);
            }

        }

    }
}