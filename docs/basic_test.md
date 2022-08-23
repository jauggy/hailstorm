# Ping test
In this test we will be checking the functionality of the most basic Tachyon command, [`c.system.ping`](https://github.com/beyond-all-reason/teiserver/blob/master/documents/tachyon/system.md#csystemping).

## Boilerplate
We start by naming the module according to the requirements of `Beans.Tests.<<NAME>>` and given our test is for the ping command it makes sense to go with `Beans.Tests.Ping`. Next up we have a brief moduledoc to explain the purpose of this test. It's such a simple test we've barely written anything here.

We have `use Tachyon` to give us all the required helper functions to make our life easier and then declare `@ping_user_params` to make it easier to later create/use the user.

## perform()
We start by making a call to `new_connection` and pass in the previously defined `@ping_user_params`. This will connect us to the user, if the user doesn't already exist it will also create it for us. We get back both the socket and the user though we discard the user as we don't need it for this test.

We make use of `tachyon_send` to send our command. We need to use the socket as the first argument but the second is a map based on the command as explained in the [documentation for `c.system.ping`](https://github.com/beyond-all-reason/teiserver/blob/master/documents/tachyon/system.md#csystemping).

Finally we use a `case` statement around `tachyon_recv` where we once again use the socket. In this instance we are waiting for a response from the server. The function returns a list and depending on the the response we either want to return an `:ok` or an error combined with a message explaining what went wrong.

## Conclusion
The ping is an incredibly simple test but nicely demonstrates setting up a connection/user, sending a message and checking the receipt of the message.