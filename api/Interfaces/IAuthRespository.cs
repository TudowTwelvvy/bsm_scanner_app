using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace api.Interfaces
{
    public interface IAuthRespository
    {
        public Task<string> RegisterAsync(string email, string password, string displayName);
        public Task<string> LoginAsync(string email, string password);
    }
}