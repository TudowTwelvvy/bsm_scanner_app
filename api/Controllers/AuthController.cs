using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Data;
using api.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/auth")]
    [ApiController]
    public class AuthController: ControllerBase
    {
        private IAuthRespository _authRespository;
        public AuthController(IAuthRespository authRespository)
        {
            _authRespository = authRespository;
        }

        
    }
}