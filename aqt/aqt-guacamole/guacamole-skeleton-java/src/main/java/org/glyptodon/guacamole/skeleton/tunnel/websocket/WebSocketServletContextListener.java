/*
 * Copyright (C) 2015 Glyptodon LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package org.glyptodon.guacamole.skeleton.tunnel.websocket;

import java.util.Arrays;
import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.websocket.DeploymentException;
import javax.websocket.server.ServerContainer;
import javax.websocket.server.ServerEndpointConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * ServletContextListener implementation which loads the WebSocket tunnel if
 * the servlet container supports JSR-356.
 *
 * @author Michael Jumper
 */
public class WebSocketServletContextListener implements ServletContextListener {

    /**
     * Logger for this class.
     */
    private final Logger logger = LoggerFactory.getLogger(WebSocketServletContextListener.class);

    @Override
    public void contextInitialized(ServletContextEvent servletContextEvent) {

        logger.info("Loading JSR-356 WebSocket support...");

        // Get container
        ServletContext servletContext = servletContextEvent.getServletContext();
        ServerContainer container = (ServerContainer) servletContext.getAttribute("javax.websocket.server.ServerContainer");
        if (container == null) {
            logger.warn("ServerContainer attribute required by JSR-356 is missing. Cannot load JSR-356 WebSocket support.");
            return;
        }

        // Build configuration for WebSocket tunnel
        ServerEndpointConfig config =
                ServerEndpointConfig.Builder.create(WebSocketTunnelEndpoint.class, "/websocket-tunnel")
                                            .configurator(new WebSocketTunnelEndpoint.Configurator())
                                            .subprotocols(Arrays.asList(new String[]{"guacamole"}))
                                            .build();

        try {

            // Add configuration to container
            container.addEndpoint(config);

        }
        catch (DeploymentException e) {
            logger.error("Unable to deploy WebSocket tunnel.", e);
        }

    }

    @Override
    public void contextDestroyed(ServletContextEvent servletContextEvent) {
        // No destruction needed
    }

}
